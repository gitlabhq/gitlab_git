require_relative 'log_parser'

module Gitlab
  module Git
    class GitStats
      attr_accessor :repo, :ref

      def initialize repo, ref
        @repo, @ref = repo, ref
      end

      def log
        log = nil
        Grit::Git.with_timeout(15) do
          # Limit log to 8k commits to avoid timeout for huge projects
          args = ['-8000', '--format=%aN%x0a%aE%x0a%cd', '--date=short', '--shortstat', '--no-merges']
          log = repo.git.run(nil, 'log', nil, {}, args)
        end

        log
      rescue Grit::Git::GitTimeout
        nil
      end

      def parsed_log
        LogParser.parse_log(log)
      end
    end
  end
end
