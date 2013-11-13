module GitSpelunk
  class FileContext
    def initialize(file, line_number=1)
      @file = file
      @line_number
    end

    def set_line_number()

    end

    def go_to_sha_parent(sha)
      sha
    end

    def get_blame
      @file.blame
    end

    def get_line_commit_info
    end
  end
end

