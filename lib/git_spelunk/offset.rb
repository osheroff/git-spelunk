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

    def chunks
      @chunks ||= diff_chunks(@repo.diff(@parent.id, @sha, @file_name))
    end

    def at_beginning_of_time?
      @parent.nil?
    end

    def unable_to_trace_lineage?
      @parent && (@chunks.nil? || target_chunk.nil?)
    end

    def first_commit_for_file?

    end

    def line_number_to_parent
      return :at_beginning_of_time unless @parent && chunks
      chunk = target_chunk(@line_number)
      return :unable_to_trace unless chunk

      parent_starting_line, parent_total_lines = parent_start_and_total(stats_line(chunk))
      return :first_commit_for_file if parent_starting_line == 0 && parent_total_lines == 0

      chunk_starting_line, chunk_total_lines = src_start_and_total(stats_line(chunk))
      parent_line_offset = find_parent_line_number(diff_lines(chunk), @line_number, chunk_starting_line, chunk_total_lines)
      parent_starting_line + parent_line_offset
    end

    private

    def diff_chunks(diffs)
      return nil if diffs.empty?
      # split it into chunks: [["@@ -10,13 +10,18 @@", diffs], ["@@ -20,13 +20,18 @@", diffs, diff]]
      multiple_chunks = diffs[0].diff.split(/(@@ \-\d+,\d+ \+\d+,\d+ @@.*?\n)/)
      # Discard file name line
      multiple_chunks[1..multiple_chunks.length].each_slice(2).to_a
    end


    def target_chunk(line_number)
      chunks.select {|chunk| has_line?(chunk, line_number)}[0]
    end

    def has_line?(chunk, line_number)
      starting_line, total_lines = src_start_and_total(stats_line(chunk))
      starting_line + total_lines >= line_number
    end

    def src_start_and_total(line)
      # Get the offset and line number where lines were added
      # @@ -3,10 +3,17 @@ optionally a line\n   unchnaged_line_1\n-    deleted_line_1\n+    new_line_1"
      line.scan(/\+(\d+),(\d+)/).first.map { |str| str.to_i }
    end

    def parent_start_and_total(line)
      line.scan(/\-(\d+),(\d+)/).first.map { |str| str.to_i }
    end

    def find_parent_line_number(lines, src_line_number, src_starting_line, src_number_of_lines)
      target_line_offset = src_line_number - src_starting_line
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

    def src_line?(line)
      # Src line will either have a "+" or will be an unchanged line
      line[0] != '-'
    end

    def parent_line?(line)
      # Src line will either have a "-" or will be an unchanged line
      line[0] != '+'
    end

    def stats_line(chunk)
      chunk[0]
    end

    def diff_lines(chunk)
      chunk[1].split("\n")
    end
  end
end
