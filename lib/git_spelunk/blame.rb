module GitSpelunk
  BlameLine = Struct.new(:line_number, :old_line_number, :sha, :commit, :filename, :content)
  class EmptyBlame < StandardError ; end
  class Blame < Grit::Blame
    def rugged_blame(repo_path, file_path, options={})
      repo = Rugged::Repository.discover(repo_path || './')
      blame = Rugged::Blame.new(repo, file_path)#, newest_commit: '31d7fed5')
      return repo, blame
    end

    def process_raw_blame(output)
      lines = []
      commits = {}
      commit_file_map = {}
      path = 'lib/git_spelunk/blame.rb'
      repo, r_blame = rugged_blame('./', path)

       # raise EmptyBlame.new if output.empty?

       # split_output = output.split(/^(\w{40} \d+ \d+(?: \d+)?\n)/m)
       # split_output.shift if split_output.first.empty?

      total_lines = r_blame.to_a.inject(0) {|s, l| s + l[:lines_in_hunk]}
      lines = []

      (1..total_lines).each do |i|
        hunk = r_blame.for_line(i)
      #lines = r_blame.each.map do |hunk|
        #lines = split_output.each_slice(2).map do |sha_line, rest|
        sha = hunk[:final_commit_id]
        old_lineno = hunk[:orig_start_line_number]
        lineno = hunk[:final_start_line_number]
        #sha_split = sha_line.split(' ')
        #sha, old_lineno, lineno = sha_split[0], sha_split[1].to_i, sha_split[2].to_i

        # indicate we need to fetch this sha in the bulk-fetch
        commits[sha] = nil

        #if rest =~ /^filename (.*)$/
        #  commit_file_map[sha] = $1
        #end
        commit_file_map[sha] = hunk[:orig_path]

        #data = rest.split("\n").detect { |l| l[0] == "\t" }[1..-1]
        tree_route = hunk[:orig_path].split("/")
        node_sha = sha
        target = nil
        tree_route << ''
        tree_route.each do |node|
          obj = repo.lookup(node_sha)
          case obj
          when Rugged::Tree
            node_sha = obj[node][:oid]
          when Rugged::Commit
            node_sha = obj.tree[node][:oid]
          when Rugged::Blob
            target = obj
          end
        end
        data = target.content.split("\n")
        lines << { :data => data[i-1], :sha => sha, :filename => commit_file_map[sha], :old_line_number => old_lineno, :line_number => lineno }
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

