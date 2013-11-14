require 'curses'

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
  end
end

