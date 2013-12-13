require 'grit'
require 'fileutils'
require 'git_spelunk/blame'

module GitSpelunk
  class FileContext
    attr_accessor :line_number
    attr_reader :repo, :sha, :file

    def initialize(file, options = {})
      @sha = options[:sha] || 'HEAD'
      @line_number = options[:line_number] || 1

      @repo = options.fetch(:repo) do
        repo_directory = find_repo_from_file(file)
        @file = File.expand_path(file).sub(%r{^#{repo_directory}/}, '')
        Grit::Repo.new(repo_directory)
      end

      @file ||= options.fetch(:file)
      @commit_cache = {}
    end


    def clone_for_parent_sha(line_number)
      new_sha = sha_for_line(line_number) + "~1"
      GitSpelunk::FileContext.new(@file, {:sha => new_sha, :repo => @repo, :file => @file})
    end

    def get_line_for_sha_parent(line_number)
      o = GitSpelunk::Offset.new(@repo, @file, sha_for_line(line_number), @new_to_old[line_number])
      o.line_number_to_parent
    end

    def find_repo_from_file(file)
      file = './' + file unless file.start_with?('/')
      targets = File.expand_path(file).split('/')
      targets.pop
      while !File.directory?(targets.join("/") + "/.git")
        targets.pop
      end

      if targets.empty?
        nil
      else
        targets.join("/")
      end
    end

    def get_blame
      @blame_data ||= begin
        @new_to_old = {}
        @line_to_sha = {}
        blame = GitSpelunk::Blame.new(@repo, @file, @sha)
        blame.lines.each do |line|
          @new_to_old[line.line_number] = line.old_line_number
        end
        blame.lines
      end
      @blame_data
    end

    def sha_for_line(line)
      @blame_data[line - 1].sha
    end

    def get_line_commit_info(line)
      get_blame
      abbrev = sha_for_line(line)
      commit = (@commit_cache[abbrev] ||= @repo.commit(abbrev))
      return nil unless commit

      author_info = commit.author_string.split(" ")
      tz = author_info.pop
      utc = Time.at(author_info.pop.to_i)
      [
        "commit " + commit.id,
        "Author: " + author_info.join(" "),
        "Date: " + utc.to_s
      ].join("\n") + "\n\n" + "     " + commit.short_message
    end
  end
end

