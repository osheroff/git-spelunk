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
  class Offset
    attr_reader :repo, :file_name, :sha, :hunks

    def initialize(repo, file_name, sha, line_number)
      @repo = repo
      @file_name = file_name
      @sha = sha
      @line_number = line_number
      @commit = @repo.lookup(@sha)
      @parent = @commit.parents[0]
    end

    STATS_PATTERN=/@@ \-(\d+),(\d+) \+(\d+),(\d+) @@/
    class Chunk
      attr_reader :minus_offset, :minus_length, :plus_offset, :plus_length, :lines

      def initialize(hunk)
        @minus_offset = hunk.old_start
        @minus_length = hunk.old_lines
        @plus_offset = hunk.new_start
        @plus_length = hunk.new_lines

        @lines = hunk.lines
      end

      def has_line?(line_number)
        plus_offset <= line_number && line_number <= (plus_offset + plus_length)
      end

      LineBlock = Struct.new(:offset, :data) do
        def initialize(offset, line)
          super(offset, [line])
        end

        def type
          data.first.line_origin
        end

        def size
          data.size
        end

        def <<(other)
          data << other
        end
      end

      def find_parent_line_number(target)
        return 1 if target == 1 
        # separate in blocks of lines with the same prefix

        old_line_number = minus_offset
        new_line_number = plus_offset

        blocks = []
        lines.each do |l|
          last_block = blocks.last

          if last_block.nil? || last_block.type != l.line_origin
            blocks << LineBlock.new(old_line_number, l)
          else
            last_block << l
          end

          if l.line_origin == :context || l.line_origin == :addition
            if new_line_number == target
              # important: we don't finish building the structure.
              break
            end

            new_line_number += 1
          end

          if l.line_origin == :deletion || l.line_origin == :context
            old_line_number += 1
          end
        end

        addition_block = blocks.pop
        last_old_block = blocks.last

        if last_old_block.type == :context
          # if the previous context existed in both, just go to the end of that.
          last_old_block.offset + (last_old_block.size - 1)
        else
          # offset N lines into the block that was removed to create the target block, but don't go beyond the edge of it.
          last_old_block.offset + [addition_block.size - 1, last_old_block.size].min
        end
      end
    end

    def hunks
      @hunks ||= begin
        diff = @parent.diff(@commit, paths: [@file_name])
        return nil unless diff

        diff.patches[0].hunks.map { |h| Chunk.new(h) } 
      end
    end

    def line_number_to_parent
      return :at_beginning_of_time unless @parent && hunks
      chunk = target_chunk(@line_number)
      return :unable_to_trace unless chunk

      return :first_commit_for_file if chunk.minus_offset == 0 && chunk.minus_length == 0

      chunk.find_parent_line_number(@line_number)
    end

    private

    def target_chunk(line_number)
      hunks.find { |c| c.has_line?(line_number) }
    end
  end
end
