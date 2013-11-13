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
    end

    class RepoWindow < Window
      def initialize(height, offset)
        @window = Curses::Window.new(height, Curses.lines, offset, 0)
      end

      def set_content(content)
        draw_status_line
        draw_bottom_line
        @window.refresh
      end

      def draw_status_line
        with_highlighting do
          @window.addstr("hello\n")
        end
      end

      def draw_bottom_line
        with_highlighting do
          @window.addstr("world\n")
        end
      end
    end

    class PagerWindow
      def initialize(height)
        @window = Curses::Window.new(height, Curses.lines, 0, 0)
      end
    end

    def initialize
      Curses.init_screen
      calculate_heights!
      @pager = PagerWindow.new(@pager_height)
      @repo = RepoWindow.new(@repo_height, @pager_height)
      @repo.set_content("hello")
    end

    def calculate_heights!
      @repo_height = (Curses.lines.to_f * 0.20).to_i
      @pager_height = Curses.lines  - @repo_height
    end
  end
end
