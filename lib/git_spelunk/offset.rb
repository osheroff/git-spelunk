# Given a sha and a line_number in this sha, this module calculates the corresponding line number in sha's parent.
# 1. It uses git diff for the sha & its parent to get all the diff chunks.
# 2. It then calculates which chunk given line_number belongs to.
# 3. Once found the target chunk, it then goes to the sha's line_number in the diff
# 4. It then calculate parent's line number by ignoring changes for sha in the diff
#
# git diff 6d405155..379120f
# --- a/app/assets/javascripts/lib/user_assume/chat_extension.module.js
# +++ b/app/assets/javascripts/lib/user_assume/chat_extension.module.js
# @@ -1,7 +1,6 @@
# -/*globals ChatLotus*/
#  module.exports = Em.Object.extend({
# -  chatService: ChatLotus.Service,
# -  hasChatEnabled: Em.computed.oneWay('chatService.hasChatEnabled'),
# +  ChatService: ChatLotus.Service,
# +  hasChatEnabled: Em.computed.oneWay('ChatService.hasChatEnabled'),
#    previousAvailablity: false,
#
#    detach: function() {
# @@ -19,10 +18,10 @@ module.exports = Em.Object.extend({
#    },
#
#    _isChatAvailable: function() {
# -    return this.get('chatService.Availability.available');
# +    return this.getPath('ChatService.Availability.available');
#    },
#
#    _toggleChatAvailability: function() {
# -    this.get('chatService.Availability').toggleAvailability();
# +    this.getPath('ChatService.Availability').toggleAvailability();
#    }
#  });


module GitSpelunk
  require 'grit'

  class Offset
    attr_reader :repo, :file_name, :sha, :chunks

    def initialize(repo, file_name, sha, line_number)
      @repo = repo
      @file_name = file_name
      @sha = sha
      @line_number = line_number
      @parent = @repo.commits(@sha)[0].parents[0]
      true
    end

    STATS_PATTERN=/@@ \-(\d+),(\d+) \+(\d+),(\d+) @@/
    class Chunk
      attr_reader :minus_offset, :minus_length, :plus_offset, :plus_length, :lines

      def initialize(data)
        @minus_offset, @minus_length, @plus_offset, @plus_length = *extract_stats(data[0])
        @lines = data[1..-1]
      end

      def has_line?(line_number)
        plus_offset <= line_number && line_number <= (plus_offset + plus_length)
      end

      def find_parent_line_number(target)
        target_line_offset = target - self.plus_offset
        current_line_offset = parent_line_offset = diff_index = 0

        lines.each do |line|
          break if current_line_offset == target_line_offset && src_line?(line)

          if src_line?(line)
            current_line_offset += 1
          end

          if parent_line?(line)
            parent_line_offset += 1
          end

          diff_index += 1
        end

        # find last contiguous bit of diff, and try to offset into that.
        removals = additions = 0
        diff_index -= 1

        while diff_index > 0
          line = lines[diff_index]

          break unless ["-", "+"].include?(line[0])

          if parent_line?(line)
            removals += 1
          else
            additions += 1
          end

          diff_index -= 1
        end

        forward_push = [additions, removals - 1].min
        (parent_line_offset - removals) + forward_push
      end

      private

      def extract_stats(l)
        #@@ -1,355 +1,355 @@
        l.scan(STATS_PATTERN).first.map(&:to_i)
      end

      def src_line?(line)
        # Src line will either have a "+" or will be an unchanged line
        line[0] != '-'
      end

      def parent_line?(line)
        # Src line will either have a "-" or will be an unchanged line
        line[0] != '+'
      end
    end

    def chunks
      @chunks ||= begin
        diffs = @repo.diff(@parent.id, @sha, @file_name)
        return nil if diffs.empty?

        chunks = diffs[0].diff.split(/\n/).inject([[]]) do |arr, line|
          arr.push([]) if line =~ STATS_PATTERN
          arr.last << line
          arr
        end

        chunks[1..-1].map { |c| Chunk.new(c) } # slice off first chunk -- it's just the filename
      end
    end

    def at_beginning_of_time?
      @parent.nil?
    end

    def unable_to_trace_lineage?
      @parent && (@chunks.nil? || target_chunk.nil?)
    end

    def line_number_to_parent
      return :at_beginning_of_time unless @parent && chunks
      chunk = target_chunk(@line_number)
      return :unable_to_trace unless chunk

      return :first_commit_for_file if chunk.minus_offset == 0 && chunk.minus_length == 0

      chunk.minus_offset + chunk.find_parent_line_number(@line_number)
    end

    private

    def target_chunk(line_number)
      chunks.find { |c| c.has_line?(line_number) }
    end
  end
end
