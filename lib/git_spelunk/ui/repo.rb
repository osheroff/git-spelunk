module GitSpelunk
  class UI
    class RepoWindow < Window
      def initialize(height, offset)
        @window = Curses::Window.new(height, Curses.cols, offset, 0)
        @offset = offset
        @height = height
        @content = ""
      end

      attr_accessor :content, :command_mode, :command_buffer

      def draw
        @window.setpos(0,0)
        draw_status_line
        @window.addstr(@content + "\n") if content
        @window.addstr("\n" * (@height - @content.split("\n").size - 2))
        @window.refresh
      end

      def draw_status_line
        with_highlighting do
          @window.addstr("navigation: j k CTRL-D CTRL-U   ")
          @window.addstr("history: [ ]   ")
          @window.addstr("search: / ? n N   ")
          @window.addstr("git-show: s   ")
          @window.addstr("quit: q   ")
          @window.addstr(" " * line_remainder + "\n")
        end
      end
    end
  end
end
