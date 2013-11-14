require 'curses'

ACTIVE_SHA_COLOR=1

module GitSpelunk
  class UI
    class Window
      def with_highlighting
        @window.attron(Curses::A_STANDOUT)
        yield
      ensure
        @window.attroff(Curses::A_STANDOUT)
      end

      def line_remainder
        Curses.cols - @window.curx - 1
      end
    end

    class RepoWindow < Window
      def initialize(height, offset)
        @window = Curses::Window.new(height, Curses.cols, offset, 0)
        @height = height
        @content = ""
      end

      attr_accessor :content

      def draw
        @window.setpos(0,0)
        draw_status_line
        @window.addstr(@content + "\n") if content
        @window.addstr("\n" * (@height - @content.split("\n").size - 2))

        draw_bottom_line
        @window.refresh
      end

      def draw_status_line
        with_highlighting do
          @window.addstr("navigation: j k CTRL-D CTRL-U")
          @window.addstr(" " * line_remainder + "\n")
        end
      end

      def draw_bottom_line
        with_highlighting do
          @window.addstr(" " * line_remainder + "\n")
        end
      end
    end

    class PagerWindow < Window
      def initialize(height)
        @window = Curses::Window.new(height, Curses.cols, 0, 0)
        @height = height
        @cursor = 1
        @top = 1
      end

      attr_accessor :data

      def draw
        @window.clear
        @window.setpos(0,0)
        line_number_width = (data.size + 1).to_s.size

        active_sha = data[@cursor - 1][0]

        data[@top - 1,@height].each_with_index do |b, i|
          sha, content = *b
          line_number = i + @top

          if sha == active_sha
            @window.attron(Curses::color_pair(ACTIVE_SHA_COLOR))
          end

          if @cursor == line_number
            with_highlighting { @window.addstr(sha) }
          else
            @window.addstr(sha)
          end

          @window.addstr(" %*s " % [line_number_width, line_number])
          @window.addstr(content[0,line_remainder])
          @window.addstr("\n")
          @window.attroff(Curses::color_pair(ACTIVE_SHA_COLOR))
        end
        @window.refresh
        @window.setpos(0,0)
      end

      attr_accessor :top

      def bufbottom
        @top + (@height - 1)
      end

      def cursorup
        return if @cursor == 1
        @cursor -= 1
        adjust_top!
      end

      def cursordown
        return if @cursor >= data.size
        @cursor += 1
        adjust_top!
      end

      def pageup
        previous_offset = @cursor - @top
        @cursor -= @height / 2
        if @cursor < 1
          @cursor = 1
        end

        @top = @cursor - previous_offset
        adjust_top!
      end

      def pagedown
        previous_offset = @cursor - @top
        @cursor += @height / 2
        if @cursor > data.size
          @cursor = data.size
        end

        @top = @cursor - previous_offset
        adjust_top!
      end

      def go_top
        @top = @cursor = 1
      end

      def go_to(l)
        previous_offset = @cursor - @top
        @cursor = l
        @top = @cursor - previous_offset
        adjust_top!
      end


      def go_bottom
        @cursor = data.size
        @top = data.size - (@height - 1)
      end

      def adjust_top!
        if @top < 1
          @top = 1
        end

        if @top > @cursor
          @top = @cursor
        end

        while @cursor > bufbottom
          @top += 1
        end
      end

      attr_reader :cursor, :top
    end

    def initialize(file_context)
      Curses.init_screen
      Curses.start_color
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

    def handle_key(key)
      @heartbeat = Time.now
      case key
      when Curses::KEY_DOWN, 'n', 'j'
        @pager.cursordown
      when Curses::KEY_UP, 'p', '-', 'k'
        @pager.cursorup
      when Curses::KEY_CTRL_D, ' '
        @pager.pagedown
      when Curses::KEY_CTRL_U
        @pager.pageup
      when 'G'
        @pager.go_bottom
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
      when 'q'
        exit
      end
    end
  end
end

