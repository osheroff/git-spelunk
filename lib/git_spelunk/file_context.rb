module GitSpelunk
  class FileContext
    def initialize(file, line_number=1)
      @file = file
      @line_number = line_number
    end

    attr_accessor :line_number

    def go_to_sha_parent(sha)
      sha
    end

    def get_blame
      lines = File.readlines("/Users/ben/src/zendesk/app/models/ticket.rb")
      lines.map do |l|
        ["abcdef", l.chomp]
      end
    end

    def get_line_commit_info
    end
  end
end

