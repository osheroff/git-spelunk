require 'open3'

module GitSpelunk
  BlameLine = Struct.new(:line_number, :old_line_number, :sha, :commit, :filename, :content)
  class EmptyBlame < StandardError ; end
  class Blame
    def initialize(repo, file, sha)
      @lines = nil
      @repo = repo
      @file = file
      @sha = sha
    end
    
    def lines
      return @lines if @lines
      cmd = ["git", "--git-dir", @repo.path, "blame", "--porcelain", @sha, "--", @file]
      output, err, status = Open3.capture3(*cmd)
      @lines ||= process_raw_blame(output)
    end

    def process_raw_blame(output)
      commits = {}
      commit_file_map = {}

      raise EmptyBlame.new if output.empty?

      split_output = output.split(/^(\w{40} \d+ \d+(?: \d+)?\n)/m)
      split_output.shift if split_output.first.empty?

      lines = split_output.each_slice(2).map do |sha_line, rest|
        sha_split = sha_line.split(' ')

        sha, old_lineno, lineno = sha_split[0], sha_split[1].to_i, sha_split[2].to_i

        commits[sha] ||= @repo.lookup(sha)

        if rest =~ /^filename (.*)$/
          commit_file_map[sha] = $1
        end

        data = rest.split("\n").detect { |l| l[0] == "\t" }[1..-1]
        { :data => data, :sha => sha, :filename => commit_file_map[sha], :old_line_number => old_lineno, :line_number => lineno }
      end

      lines.map do |hash|
        GitSpelunk::BlameLine.new(hash[:line_number], hash[:old_line_number], hash[:sha], commits[hash[:sha]], hash[:filename], hash[:data])
      end
    end
  end
end
