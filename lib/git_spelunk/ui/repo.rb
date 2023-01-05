module GitSpelunk
  class UI
    class RepoWindow
      attr_accessor :content, :command_mode, :command_buffer, :height

      def initialize(height)
        @height = height
        self.content = ""
      end

      def draw
        styles = Dispel::StyleMap.new(@height)
        styles.add(:reverse, 0, 0..999)
        view = [status_line] + content.split("\n")
        view = Array.new(@height).each_with_index.map {|_,i| view[i] }
        [view, styles]
      end

      private

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
