require_relative 'log_parser'

module Gitlab
  module Git
    class GitStats
      attr_accessor :repo, :ref, :timeout

      def initialize(repo, ref, timeout = 30)
        @repo, @ref, @timeout = repo, ref, timeout
      end

      # Returns a string of log information; equivalent to running 'git log`
      # with these options:
      #
      # -6000
      # --format=%aN%x0a%aE%x0a%cd
      # --date=short
      # --shortstat
      # --no-merges
      # --diff-filter=ACDM
      def log
        commit_strings = []
        walker = Rugged::Walker.new(repo.rugged)
        walker.push(repo.lookup(ref))
        walker.each(limit: 6000) do |commit|
          # Skip merge commits
          next if commit.parents.length > 1

          g_commit = Gitlab::Git::Commit.new(commit)

          commit_strings << [
            g_commit.author_name,
            g_commit.author_email,
            g_commit.committed_date.strftime("%Y-%m-%d"),
            "",
            status_string(g_commit)
          ].join("\n")
        end

        commit_strings.join("\n")
      end

      def parsed_log
        LogParser.parse_log(log)
      end

      private

      # Returns a string describing the files changed, additions and deletions
      # for +commit+
      def status_string(commit)
        stats = commit.stats

        status = "#{num_files_changed(commit)} files changed"
        status << ", #{stats.additions} insertions" if stats.additions > 0
        status << ", #{stats.deletions} deletions" if stats.deletions > 0
        status
      end

      # Returns the number of files that were either added, copied, deleted, or
      # modified by +commit+
      def num_files_changed(commit)
        count = 0

        diff = commit.diff_from_parent
        diff.find_similar!
        diff.each_delta do |d|
          count += 1 if d.added? || d.copied? || d.deleted? || d.modified?
        end

        count
      end
    end
  end
end
