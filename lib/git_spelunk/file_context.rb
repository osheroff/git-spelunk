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

    def clone_for_blame_line(blame_line)
      new_sha = blame_line.sha + "~1"
      GitSpelunk::FileContext.new(blame_line.filename, {:sha => new_sha, :repo => @repo, :file => blame_line.filename})
    end

    def get_line_for_sha_parent(blame_line)
      o = GitSpelunk::Offset.new(@repo, blame_line.filename, blame_line.sha, blame_line.old_line_number)
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
        GitSpelunk::Blame.new(@repo, @file, @sha).lines
      end
    end

    def get_line_commit_info(blame_line)
      get_blame
      commit = blame_line.commit
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

