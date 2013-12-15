require 'git_spelunk/ui/window'
require 'git_spelunk/ui/pager'
require 'git_spelunk/ui/repo'
require 'git_spelunk/ui/status'
require 'curses'

module GitSpelunk
  class UI
    def initialize(file_context)
      init_curses

      calculate_heights!
      @file_context = file_context
      @history = [file_context]

      @pager = PagerWindow.new(@pager_height)
      @pager.data = @file_context.get_blame

      @repo = RepoWindow.new(@repo_height, @pager_height)

      @status = StatusWindow.new(1, Curses.lines - 1)
      set_status_message
    end

    def init_curses
      Curses.init_screen
      Curses.start_color
      Curses.raw
      Curses.nonl
      Curses.noecho
      Curses.curs_set(0)
      screen = Curses.stdscr
      screen.refresh
      screen.keypad(1)
      Curses.init_pair(ACTIVE_SHA_COLOR, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    end

    def calculate_heights!
      @repo_height = [(Curses.lines.to_f * 0.20).to_i, 6].max
      @pager_height = Curses.lines  - @repo_height - 1
      @status_height = 1
    end

    def run
      @repo.content = @file_context.get_line_commit_info(@pager.blame_line)
      begin
        [@pager, @repo, @status].each(&:draw)
        handle_key(Curses.getch)
      end while true
    end

    def set_status_message
      @status.status_message = "#{@file_context.file} @ #{@file_context.sha}"
    end

    def after_navigation
      @pager.highlight_sha = true
      @repo.content = @file_context.get_line_commit_info(@pager.blame_line)
      @repo.draw
      @status.exit_command_mode!
      @status.clear_onetime_message!
    end

    def history_back
      @status.set_onetime_message("Rewinding...")
      goto = @file_context.get_line_for_sha_parent(@pager.blame_line)
      if goto.is_a?(Fixnum)
        @history.push(@file_context)

        @file_context = @file_context.clone_for_parent_sha(@pager.blame_line.sha)
        @pager.data = @file_context.get_blame
        @pager.go_to(goto)

        # force commit info update
        @status.clear_onetime_message!
        set_status_message
        @last_line = nil
      elsif goto == :at_beginning_of_time
        @status.set_onetime_message("At beginning of repository history!")
      elsif goto == :unable_to_trace
        @status.set_onetime_message("Unable to trace lineage of file line")
      elsif goto == :first_commit_for_file
        @status.set_onetime_message("At first appearance of file")
      end
    end

    def history_forward
      if @history.last
        @file_context = @history.pop
        @pager.data = @file_context.get_blame
        @pager.go_to(@file_context.line_number)

        @status.clear_onetime_message!
        set_status_message

        # force commit info update
        @last_line = nil
      end
    end

    def handle_key(key)
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
        @status.command_buffer += key
      when Curses::KEY_CTRL_M
        if @status.command_buffer != ''
          @pager.go_to(@status.command_buffer.to_i)
        end
        after_navigation
      when 'G'
        if @status.command_buffer != ''
          @pager.go_to(@status.command_buffer.to_i)
        else
          @pager.go_bottom
        end
        after_navigation
      when '['
        history_back
      when ']'
        history_forward
      when 's'
        sha = @pager.blame_line.sha
        Curses.close_screen
        system("git -p --git-dir='#{@file_context.repo.path}' show #{sha} | less")
        Curses.stdscr.refresh
      when '/', '?'
        @status.command_buffer = key
        @status.draw

        line = getline
        if line
          @pager.search(line, false, key == '?')
        end
        @status.exit_command_mode!
      when 'n'
        @pager.search(nil, true, false)
        after_navigation
      when 'N'
        @pager.search(nil, true, true)
        after_navigation
      when 'q', Curses::KEY_CTRL_C
        exit
      end
    end

    # you'd really think there was a better way
    def getline
      while ch = Curses.getch
        case ch
        when Curses::KEY_CTRL_C
          @status.command_buffer = ''
          return
        when Curses::KEY_CTRL_M
          return @status.command_buffer[1..-1]
        when Curses::KEY_BACKSPACE, Curses::KEY_CTRL_H, 127
          if @status.command_buffer == "/"
            return
          end
          @status.command_buffer.chop!
        else
          if ch.is_a?(String)
            @status.command_buffer += ch
          end
        end
        @status.draw
      end
    end
  end
end

