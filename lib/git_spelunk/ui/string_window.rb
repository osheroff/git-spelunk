module GitSpelunk
  class UI
    class StringWindow
      attr_accessor :window, :height, :offset

      def initialize(height, offset)
        @height, @offset = height, offset
      end

      def draw
        self.window ||= Curses::Window.new(height, width, offset, 0)
        window.setpos(0,0)
        lines = string.split("\n")[0...height]
        lines.fill("", lines.size, height - lines.size)
        lines.each do |line|
          line = line[0...width]
          line.ljust(width, " ")
          window.addstr(line + "\n")
        end
        window.refresh
      end

      def width
        Curses.cols
      end
    end
  end
end
