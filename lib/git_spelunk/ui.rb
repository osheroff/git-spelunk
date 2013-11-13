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
        @window.addstr(@content + "\n")
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
      def initialize(height, context)
        @window = Curses::Window.new(height, Curses.cols, 0, 0)
        @height = height
        @context = context
        @cursor = context.line_number
        @top = context.line_number
      end

      def data
        @data ||= @context.get_blame
      end

      def draw
        @window.clear
        @window.setpos(0,0)
        line_number_width = (data.size + 1).to_s.size

        data[@top - 1,@height].each_with_index do |b, i|
          sha, content = *b
          line_number = i + @top

          if @cursor == line_number
            with_highlighting { @window.addstr(sha) }
          else
            @window.addstr(sha)
          end

          @window.addstr(" %*s " % [line_number_width, line_number])
          @window.addstr(content[0,line_remainder])
          @window.addstr("\n")
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
      screen = Curses.stdscr
      screen.refresh
      screen.keypad(1)

      calculate_heights!
      @pager = PagerWindow.new(@pager_height, file_context)
      @repo = RepoWindow.new(@repo_height, @pager_height)
    end

    def calculate_heights!
      @repo_height = (Curses.lines.to_f * 0.20).to_i
      @pager_height = Curses.lines  - @repo_height
    end

    def run
      begin
        @pager.draw
        @repo.draw
        handle_key(Curses.getch)
      end while true
    end

    def handle_key(key)
      case key
      when Curses::KEY_DOWN, 'n', 'j'
        @pager.cursordown
        @repo.content = {key: "cursordown", top: @pager.top, cursor: @pager.cursor, bufbottom: @pager.bufbottom}.inspect
      when Curses::KEY_UP, 'p', '-', 'k'
        @pager.cursorup
        @repo.content = {key: "cursorup", top: @pager.top, cursor: @pager.cursor, bufbottom: @pager.bufbottom}.inspect
      when Curses::KEY_CTRL_D, ' '
        @pager.pagedown
        @repo.content = {key: "pagedown", top: @pager.top, cursor: @pager.cursor, bufbottom: @pager.bufbottom}.inspect
      when Curses::KEY_CTRL_U
        @pager.pageup
        @repo.content = {key: "pageup", top: @pager.top, cursor: @pager.cursor, bufbottom: @pager.bufbottom}.inspect
      when 'G'
        @pager.go_bottom
        @repo.content = {key: "gobottom", top: @pager.top, cursor: @pager.cursor, bufbottom: @pager.bufbottom}.inspect
      when 'q'
        exit
      end
    end
  end
end

