require 'git_spelunk/ui/window'
require 'git_spelunk/ui/pager'
require 'git_spelunk/ui/repo'
require 'curses'

module GitSpelunk
  class UI

    def initialize(file_context)
      Curses.init_screen
      Curses.start_color
      Curses.raw
      Curses.nonl
      Curses.curs_set(2)
      screen = Curses.stdscr
      screen.refresh
      screen.keypad(1)
      Curses.init_pair(ACTIVE_SHA_COLOR, Curses::COLOR_GREEN, Curses::COLOR_BLACK)

      calculate_heights!
      @file_context = file_context
      @history = [file_context]
      @pager = PagerWindow.new(@pager_height)
      @pager.data = @file_context.get_blame

      @repo = RepoWindow.new(@repo_height, @pager_height)
    end

    def calculate_heights!
      @repo_height = (Curses.lines.to_f * 0.20).to_i
      @pager_height = Curses.lines  - @repo_height
    end

    def run
      @repo.content = @file_context.get_line_commit_info(@pager.cursor)
      pause_thread
      begin
        @pager.draw
        @repo.draw
        @repo.set_cursor
        handle_key(Curses.getch)
      end while true
    end

    def pause_thread
      Thread.abort_on_exception = true
      Thread.new do
        while true
          if heartbeat_expired? && @last_line != @pager.cursor
            current_line = @pager.cursor
            content = @file_context.get_line_commit_info(current_line)
            if heartbeat_expired? && @pager.cursor == current_line
              @repo.content = content
              @repo.draw
              @last_line = current_line
            else
              @heartbeat = Time.now
            end
          end
          sleep 0.05
        end
      end
    end

    def heartbeat_expired?
      @heartbeat && (Time.now - @heartbeat).to_f > 0.30
    end

    def after_navigation
      @pager.highlight_sha = true
      @repo.exit_command_mode!
    end

    def handle_key(key)
      @heartbeat = Time.now
      case key
      when Curses::KEY_DOWN, 'j'
        @pager.cursordown
        after_navigation
      when Curses::KEY_UP, '-', 'k'
        @pager.cursorup
        after_navigation
      when Curses::KEY_CTRL_D, ' '
        @pager.pagedown
        after_navigation
      when Curses::KEY_CTRL_U
        @pager.pageup
        after_navigation
      when *(0..9).to_a.map(&:to_s)
        @repo.command_mode = true
        @repo.command_buffer += key
      when Curses::KEY_CTRL_M
        if @repo.command_buffer != ''
          @pager.go_to(@repo.command_buffer.to_i)
        end
        after_navigation
      when 'G'
        if @repo.command_buffer != ''
          @pager.go_to(@repo.command_buffer.to_i)
        else
          @pager.go_bottom
        end
        after_navigation
      when '['
        goto = @file_context.get_line_for_sha_parent(@pager.cursor)

        @file_context.line_number = @pager.cursor
        @history.push(@file_context)

        @file_context = @file_context.clone_for_parent_sha(@pager.cursor)
        @pager.data = @file_context.get_blame
        @pager.go_to(goto)
      when ']'
        if @history.last
          @file_context = @history.pop
          @pager.data = @file_context.get_blame
          @pager.go_to(@file_context.line_number)
          @pager.draw
        end
      when 's'
        @heartbeat = nil
        sha = @file_context.sha_for_line(@pager.cursor)
        Curses.close_screen
        system("git -p --git-dir='#{@file_context.repo.path}' show #{sha} | less")
        Curses.stdscr.refresh
        @pager.draw
        @repo.draw
        @pager.highlight_sha = true
      when '/'
        @repo.command_mode = true
        @repo.command_buffer = '/'
        @repo.draw
        @repo.set_cursor
        begin
          line = Curses.getstr
        rescue Interrupt
          @repo.exit_command_mode!
        end
        @search_string = line
        @pager.search(@search_string, false)
        @repo.exit_command_mode!
      when 'n'
        @pager.search(@search_string, true)
        after_navigation
      when 'q'
        exit
      end
    end
  end
end

