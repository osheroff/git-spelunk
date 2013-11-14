module GitSpelunk
  class UI
    class RepoWindow < Window
      def initialize(height, offset)
        @window = Curses::Window.new(height, Curses.cols, offset, 0)
        @offset = offset
        @height = height
        @command_mode = false
        @command_buffer = ""
        @content = ""
      end

      attr_accessor :content, :command_mode, :command_buffer

      def exit_command_mode!
        self.command_buffer = ""
        self.command_mode = false
      end

      def draw
        @window.setpos(0,0)
        draw_status_line
        @window.addstr(@content + "\n") if content
        @window.addstr("\n" * (@height - @content.split("\n").size - 2))

        draw_bottom_line
        @window.refresh
        set_cursor
      end

      def set_cursor
        Curses::stdscr.setpos(@offset + @height - 1, command_buffer.size + 1)
      end

      def draw_status_line
        with_highlighting do
          @window.addstr("navigation: j k CTRL-D CTRL-U ")
          @window.addstr("history: [ ] ")
          @window.addstr("search: / ")
          @window.addstr(" " * line_remainder + "\n")
        end
      end

      def draw_bottom_line
        if command_mode
          @window.addstr(":" + command_buffer)
          @window.addstr(" " * line_remainder)
        else
          with_highlighting do
            @window.addstr(" " * line_remainder + "\n")
          end
        end
      end
    end
  end
end
