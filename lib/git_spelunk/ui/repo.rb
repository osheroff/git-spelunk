module GitSpelunk
  class UI
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
  end
end
