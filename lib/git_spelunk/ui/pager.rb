require 'curses'

ACTIVE_SHA_COLOR=1
module GitSpelunk
  class UI
    class PagerWindow < Window
      def initialize(height)
        @window = Curses::Window.new(height, Curses.cols, 0, 0)
        @height = height
        @cursor = 1
        @top = 1
      end

      attr_accessor :data
      attr_reader :cursor, :top

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

    end
  end
end

