require 'git_spelunk/ui/pager'
require 'git_spelunk/ui/repo'
require 'git_spelunk/ui/status'

module GitSpelunk
  class UI
    def initialize(file_context)
      Dispel::Screen.open(:colors => true) do |screen|
        calculate_heights!
        @file_context = file_context
        @history = [file_context]

        @pager = PagerWindow.new(@pager_height)
        @pager.data = @file_context.get_blame

        @repo = RepoWindow.new(@repo_height)

        @status = StatusWindow.new
        set_status_message

        screen.draw *draw
        Dispel::Keyboard.output :timeout => 0.30 do |key|
          handle_key(key)
          screen.draw *draw
        end
      end
    end

    def draw
      view1, style1 = @pager.draw
      view2, style2 = @repo.draw
      view3, style3 = @status.draw

      cursor = if @typing
        [@pager_height + @repo_height, @status.command_buffer.size + 1]
      else
        [Curses.lines, Curses.cols]
      end

      [
        [view1, view2, view3].join("\n"),
        style1 + style2 + style3,
        cursor
      ]
    end

    def calculate_heights!
      @repo_height = [(Curses.lines.to_f * 0.20).to_i, 6].max
      @pager_height = Curses.lines  - @repo_height - 1
      @status_height = 1
    end

    def set_status_message
      @status.status_message = "#{@file_context.file} @ #{@file_context.sha}"
    end

    def after_navigation
      @pager.highlight_sha = true
      @status.exit_command_mode!
      @status.clear_onetime_message!
    end

    def history_back
      @status.set_onetime_message("Rewinding...")
      goto = @file_context.get_line_for_sha_parent(@pager.cursor)
      if goto.is_a?(Fixnum)
        @file_context.line_number = @pager.cursor
        @history.push(@file_context)

        @file_context = @file_context.clone_for_parent_sha(@pager.cursor)
        @pager.data = @file_context.get_blame
        @pager.go_to(goto)

        # force commit info update
        @status.clear_onetime_message!
        set_status_message
        @last_line = nil
      elsif goto == :at_beginning_of_time
        @status.set_onetime_message("At beginning of repository history!")
      elsif goto == :unable_to_trace
        @status.set_onetime_message("Unable to trace lineage of file line")
      elsif goto == :first_commit_for_file
        @status.set_onetime_message("At first appearance of file")
      end
    end

    def history_forward
      if @history.last
        @file_context = @history.pop
        @pager.data = @file_context.get_blame
        @pager.go_to(@file_context.line_number)

        @status.clear_onetime_message!
        set_status_message

        # force commit info update
        @last_line = nil
      end
    end

    def handle_key(key)
      case key
      when :"Ctrl+d", ' '
        @pager.pagedown
        after_navigation
      when :"Ctrl+u"
        @pager.pageup
        after_navigation
      when :"Ctrl+c"
        exit
      when :escape
        @pager.search_term = nil
        @status.exit_command_mode!
        @typing = false
      when :timeout
        # TODO performance only set if cursor/line changed
        @repo.content = @file_context.get_line_commit_info(@pager.cursor)
      else
        if @typing
          case key
          when String
            if key == "G" && @typing == :goto
              execute_goto
            else
              @status.command_buffer << key
            end
          when :enter
            if @typing == :search
              @pager.search(@status.command_buffer, false, key == '?')
            elsif @typing == :goto
              execute_goto
            end
            @typing = false
          end
        else
          case key
          when :down, 'j'
            @pager.cursordown
            after_navigation
          when :up, '-', 'k'
            @pager.cursorup
            after_navigation
          when *(0..9).to_a.map(&:to_s)
            @status.command_buffer = key
            @typing = :goto
          when '['
            history_back
          when ']'
            history_forward
          when 's'
            sha = @file_context.sha_for_line(@pager.cursor)
            Curses.close_screen
            system("git -p --git-dir='#{@file_context.repo.path}' show #{sha} | less")
          when '/', '?'
            @status.command_buffer = ""
            @typing = :search
          when 'n'
            @pager.search(nil, true, false)
            after_navigation
          when 'N'
            @pager.search(nil, true, true)
            after_navigation
          when 'q'
            exit
          end
        end
      end
    end

    def execute_goto
      if @status.command_buffer != ''
        @pager.go_to(@status.command_buffer.to_i)
      else
        @pager.go_bottom
      end
      after_navigation
    end
  end
end

