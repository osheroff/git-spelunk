module GitSpelunk
  class UI
    class StatusWindow
      def initialize
        @command_buffer = ""
        @status_message = ""
        @onetime_message = nil
      end

      attr_accessor :command_buffer, :status_message

      def clear_onetime_message!
        @onetime_message = nil
      end

      def set_onetime_message(message)
        @onetime_message = message
      end

      def exit_command_mode!
        self.command_buffer = nil
      end

      def draw
        styles = Dispel::StyleMap.new(1)

        view = if command_buffer.size > 0
          ":" + command_buffer
        else
          message = (@onetime_message || @status_message)
          styles.add(:reverse, 0, 0...999)
          message
        end

        [view, styles]
      end
    end
  end
end
