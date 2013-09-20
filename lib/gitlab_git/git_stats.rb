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
        Grit::Git.with_timeout(30) do
          # Limit log to 6k commits to avoid timeout for huge projects
          args = [ref, '-6000', '--format=%aN%x0a%aE%x0a%cd', '--date=short', '--shortstat', '--no-merges', '--diff-filter=ACDM']
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
