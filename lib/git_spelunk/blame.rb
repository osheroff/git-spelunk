module GitSpelunk
  BlameLine = Struct.new(:line_number, :old_line_number, :sha, :commit, :filename, :content)
  class EmptyBlame < StandardError ; end
  class Blame < Grit::Blame
    def process_raw_blame(output)
      lines = []
      commits = {}
      commit_file_map = {}

      raise EmptyBlame.new if output.empty?

      split_output = output.split(/^(\w{40} \d+ \d+(?: \d+)?\n)/m)
      split_output.shift if split_output.first.empty?

      lines = split_output.each_slice(2).map do |sha_line, rest|
        sha_split = sha_line.split(' ')

        sha, old_lineno, lineno = sha_split[0], sha_split[1].to_i, sha_split[2].to_i

        # indicate we need to fetch this sha in the bulk-fetch
        commits[sha] = nil

        if rest =~ /^filename (.*)$/
          commit_file_map[sha] = $1
        end

        data = rest.split("\n").detect { |l| l[0] == "\t" }[1..-1]
        { :data => data, :sha => sha, :filename => commit_file_map[sha], :old_line_number => old_lineno, :line_number => lineno }
      end


      # load all commits in single call
      @repo.batch(*commits.keys).each do |commit|
        commits[commit.id] = commit
      end

      @lines = lines.map do |hash|
        GitSpelunk::BlameLine.new(hash[:line_number], hash[:old_line_number], hash[:sha], commits[hash[:sha]], hash[:filename], hash[:data])
      end
    end
  end
end

