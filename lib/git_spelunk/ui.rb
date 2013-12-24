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

      cursor = if typing?
        [@pager_height + @repo_height, @status.command_buffer.size + 1]
      else
        [Curses.lines-1, Curses.cols]
      end

      [
        [view1, view2, view3].join("\n"),
        style1 + style2 + style3,
        cursor
      ]
    end

    def calculate_heights!
      @status_height = 1
      @repo_height = [(Curses.lines.to_f * 0.20).to_i, 6].max
      @pager_height = Curses.lines  - @repo_height - @status_height
    end

    def set_status_message
      @status.status_message = "#{@file_context.file} @ #{@file_context.sha}"
    end

    def set_repo_content
      @repo.content = @file_context.get_line_commit_info(@pager.blame_line)
      @repo.draw
    end

    def after_navigation
      @pager.highlight_sha = true
      set_repo_content
      @status.exit_command_mode!
      @status.clear_onetime_message!
    end

    def history_back
      @status.set_onetime_message("Rewinding...")
      goto = @file_context.get_line_for_sha_parent(@pager.blame_line)
      if goto.is_a?(Fixnum)
        @file_context.line_number = @pager.cursor
        @history.push(@file_context)

        @file_context = @file_context.clone_for_blame_line(@pager.blame_line)
        @pager.data = @file_context.get_blame
        @pager.go_to(goto)

        set_repo_content
        @status.clear_onetime_message!
        set_status_message
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
        set_repo_content

        @status.clear_onetime_message!
        set_status_message
      end
    end

    def handle_key(key)
      case key
      when :"Ctrl+d", ' ', :page_down
        @pager.pagedown
        after_navigation
      when :"Ctrl+u", :page_up
        @pager.pageup
        after_navigation
      when :"Ctrl+c"
        exit
      when :escape
        @pager.search_term = nil
        @status.exit_command_mode!
        @typing = false
      else
        if typing?
          case key
          when String
            if key == "G" && @typing == :goto
              execute_goto
            else
              @status.command_buffer << key
            end
          when :backspace then @status.command_buffer[-1..-1] = ""
          when :enter
            if @typing == :search
              typed = @status.command_buffer
              @pager.search(typed[1..-1], false, typed[0] == '?')
            elsif @typing == :goto
              execute_goto
            end
            @typing = false
            @status.command_buffer = ""
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
            sha = @pager.blame_line.sha
            Curses.close_screen
            system("git -p --git-dir='#{@file_context.repo.path}' show #{sha} | less")
          when '/', '?'
            @status.command_buffer = key
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

    def typing?
      @status.command_buffer.size > 0
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

