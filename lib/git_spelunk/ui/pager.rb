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

      def blame_line
        @data[@cursor - 1]
      end

      attr_accessor :data, :highlight_sha
      attr_reader :cursor, :top, :data

      def draw
        @window.clear
        @window.setpos(0,0)
        line_number_width = (data.size + 1).to_s.size

        active_sha = blame_line.sha

        data[@top - 1,@height].each_with_index do |b, i|
          sha, content = b.sha, b.content
          line_number = i + @top

          if sha == active_sha && highlight_sha
            @window.attron(Curses::color_pair(ACTIVE_SHA_COLOR))
          end

          if @cursor == line_number
            with_highlighting { @window.addstr(sha[0..6]) }
          else
            @window.addstr(sha[0..6])
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

      #returns position in data set, not cursor position
      def find_next_index(term, start, reverse)
        i = start
        while i < data.size && i >= 0
          if data[i].content =~ /#{term}/
            return i
          end
          i += reverse ? -1 : 1
        end
        nil
      end

      def search(term, skip_current_line, reverse)
        if term
          @search_term = term
        else
          term = @search_term # nil indicates 'use-last-term'
        end

        search_from = @cursor - 1
        if skip_current_line
          search_from += reverse ? -1 : 1
        end

        p = find_next_index(term, search_from, reverse) ||
              find_next_index(term, reverse ? data.size - 1 : 0, reverse)

        go_to(p + 1) if p
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
        if l > @data.size
          l = @data.size
        elsif l < 1
          l = 1
        end

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

