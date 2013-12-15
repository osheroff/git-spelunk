module GitSpelunk
  class UI
    class RepoWindow
      attr_accessor :content, :command_mode, :command_buffer

      def initialize(height)
        @height = height
        self.content = ""
      end

      def draw
        styles = Dispel::StyleMap.new(@height)
        styles.add(:reverse, 0, 0..999)
        [status_line + "\n" + content, styles]
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
