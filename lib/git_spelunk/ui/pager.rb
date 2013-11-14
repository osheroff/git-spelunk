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
        @highlight_sha = true
      end

      attr_accessor :data, :highlight_sha
      attr_reader :cursor, :top

      def draw
        @window.clear
        @window.setpos(0,0)
        line_number_width = (data.size + 1).to_s.size

        active_sha = data[@cursor - 1][0]

        data[@top - 1,@height].each_with_index do |b, i|
          sha, content = *b
          line_number = i + @top

          if sha == active_sha && highlight_sha
            @window.attron(Curses::color_pair(ACTIVE_SHA_COLOR))
          end

          if @cursor == line_number
            with_highlighting { @window.addstr(sha) }
          else
            @window.addstr(sha)
          end

          @window.addstr(" %*s " % [line_number_width, line_number])
          if @search_term
            content.split(/(#{@search_term})/).each do |t|
              if t == @search_term
                @window.attron(Curses::A_STANDOUT)
              end
              @window.addstr(t[0,line_remainder])
              @window.attroff(Curses::A_STANDOUT)
            end
          else
            @window.addstr(content[0,line_remainder])
          end
          @window.addstr("\n")
          @window.attroff(Curses::color_pair(ACTIVE_SHA_COLOR))
        end
        @window.refresh
        @window.setpos(0,0)
      end

      attr_accessor :top

      def search(term, skip_current_line)
        @search_term = term
        return unless term
        save_cursor = @cursor
        search_data = data.map { |d| d[1] }
        initial_position = save_cursor - (skip_current_line ? 0 : 1)
        search_data[initial_position..-1].each_with_index do |d, i|
          if d =~ /#{term}/
            go_to(initial_position + i + 1)
            return
          end
        end

        search_data[0..initial_position].each_with_index do |d, i|
          if d =~ /#{term}/
            go_to(i + 1)
            return
          end
        end
      end

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

