module GitSpelunk
  BlameLine = Struct.new(:line_number, :old_line_number, :sha, :commit, :filename, :content)
  class Blame < Grit::Blame
    def process_raw_blame(output)
      lines, final = [], []
      info, commits = {}, {}

      current_filename = nil
      # process the output
      output.split("\n").each do |line|
        if line[0, 1] == "\t"
          lines << line[1, line.size]
        elsif m = /^(\w{40}) (\d+) (\d+)/.match(line)
          commit_id, old_lineno, lineno = m[1], m[2].to_i, m[3].to_i
          commits[commit_id] = nil
          info[lineno] = [commit_id, old_lineno, current_filename]
        elsif line =~ /^filename (.*)/
          current_filename = $1
         end
      end

      # load all commits in single call
      @repo.batch(*commits.keys).each do |commit|
        commits[commit.id] = commit
      end

      # get it together
      info.sort.each do |lineno, (commit_id, old_lineno, filename)|
        commit = commits[commit_id]
        final << GitSpelunk::BlameLine.new(lineno, old_lineno, commit_id, commit, filename, lines[lineno - 1])
      end
      @lines = final
    end
  end
end

