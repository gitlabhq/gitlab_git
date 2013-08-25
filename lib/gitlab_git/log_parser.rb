module Gitlab
  module Git
    class LogParser
      # Parses the log file into a collection of commits
      # Data model:
      #   {author_name, author_email, date, additions, deletions}
      def self.parse_log(log_from_git)
        log = log_from_git.split("\n")
        collection = []

        log.each_slice(5) do |slice|
          entry = {}
          entry[:author_name] = slice[0]
          entry[:author_email] = slice[1]
          entry[:date] = slice[2]

          if slice[4]
            changes = slice[4]

            entry[:additions] = $1.to_i if changes =~ /(\d+) insertion/
            entry[:deletions] = $1.to_i if changes =~ /(\d+) deletion/
          end

          collection.push(entry)
        end

        collection
      end
    end
  end
end
