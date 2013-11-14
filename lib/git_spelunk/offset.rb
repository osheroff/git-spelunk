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

    def initialize(repo, file_name, sha)
      @repo = repo
      @file_name = file_name
      @sha = sha
      parent_sha = @repo.commits(@sha)[0].parents[0].id
      @chunks = @repo.diff(parent_sha, @sha, @file_name)
    end

    def line_number_to_parent(src_line_number)
      chunk = target_chunk(src_line_number)
      chunk_lines = lines(chunk)
      chunk_starting_line, chunk_total_lines = chunk_start_and_total(chunk_lines)
      find_parent_line_number(diff_lines(chunk_lines), src_line_number, chunk_starting_line, chunk_total_lines)
    end

    private

    def target_chunk(line_number)
      chunks.select {|chunk| has_line?(lines(chunk), line_number)}[0]
    end

    def has_line?(lines, line_number)
      starting_line, total_lines = chunk_start_and_total(lines)
      starting_line + total_lines >= line_number
    end

    def chunk_start_and_total(lines)
      line = stats_line(lines)
      line_start_and_total(line)
    end

    def line_start_and_total(line)
      # Get the offset and line number where lines were added
      # @@ -3,10 +3,17 @@ optionally a line\n   unchnaged_line_1\n-    deleted_line_1\n+    new_line_1"
      line.scan(/\+(.*)@@/)[0][0].split(",").map {|str| str.to_i}
    end

    def find_parent_line_number(lines, src_line_number, src_starting_line, src_number_of_lines)
      target_line_offset = src_line_number - src_starting_line + 1
      current_line_offset = parent_line_offset = 1

      lines.each do |line|
        break if current_line_offset == target_line_offset

        if src_line?(line)
          current_line_offset += 1
        end

        if parent_line?(line)
          parent_line_offset += 1
        end
      end

      src_starting_line + (parent_line_offset - 1)
    end

    def src_line?(line)
      # Src line will either have a "+" or will be an unchanged line
      line[0] != '-'
    end

    def parent_line?(line)
      # Src line will either have a "-" or will be an unchanged line
      line[0] != '+'
    end

    def stats_line(lines)
      lines[2]
    end

    def diff_lines(lines)
      # TODO: edge case when meta & content are combined e.g.
      # @@ -18,14 +18,14 @@ var UserAssumeController = Em.Object.extend({
      # first 3 are meta lines
      length = lines.length - 3
      lines[3..length]
    end

    def lines(chunk)
      chunk.diff.split("\n")
    end
  end
end
