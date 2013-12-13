module GitSpelunk
  class UI
    class RepoWindow < StringWindow
      attr_accessor :content, :command_mode, :command_buffer

      def initialize(height, offset)
        super
        self.content = ""
      end

      def string
        status_line + "\n" + content
      end

      private

      #with_highlighting do
      def status_line
        [
          "navigation: j k CTRL-D CTRL-U",
          "history: [ ]",
          "search: / ? n N",
          "git-show: s",
          "quit: q"
        ].join("  ")
      end
    end
  end
end
