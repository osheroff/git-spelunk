module GitSpelunk
  class UI
    class StatusWindow < Window
      def initialize(height, offset)
        @window = Curses::Window.new(height, Curses.cols, offset, 0)
        @offset = offset
        @command_buffer = ""
      end

      attr_accessor :command_buffer

      def exit_command_mode!
        self.command_buffer = ""
      end

      def set_cursor
        Curses::stdscr.setpos(@offset, command_buffer.size + 1)
      end

      def draw
        @window.setpos(0,0)
        if !command_buffer.empty?
          Curses.curs_set(1)
          @window.addstr(":" + command_buffer)
          @window.addstr(" " * line_remainder)
        else
          Curses.curs_set(0)
          with_highlighting do
            @window.addstr(" " * line_remainder + "\n")
          end
        end
        set_cursor
        @window.refresh
      end
    end
  end
end
