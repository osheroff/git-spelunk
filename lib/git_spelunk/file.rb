require 'grit'

module GitSpelunk
  class File
    def initialize(filename, sha, line=1)
      @filename = filename
      @sha = sha
      @line = line
    end

    def blame
      [
        ["abcdef", "content"],
        ["abcdef", "content"],
        ["abcdef", "content"],
        ["abcdef", "content"],
        ["abcdef", "content"]
        ["abcdef", "content"]
        ["abcdef", "content"]
        ["abcdef", "content"]
        ["abcdef", "content"]
      ]
    end
  end
end
