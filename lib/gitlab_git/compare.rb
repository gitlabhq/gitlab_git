module Gitlab
  module Git
    class Compare
      attr_accessor :commits, :commit, :diffs, :same, :limit, :timeout

      def initialize(repository, from, to, limit = 100)
        @commits, @diffs = [], []
        @commit = nil
        @same = false
        @limit = limit
        @repository = repository
        @timeout = false

        return unless from && to

        @base = Gitlab::Git::Commit.find(repository, from.try(:strip))
        @head = Gitlab::Git::Commit.find(repository, to.try(:strip))

        return unless @base && @head

        if @base.id == @head.id
          @same = true
          return
        end

        @commit = @head
        @commits = Gitlab::Git::Commit.between(repository, @base.id, @head.id)
      end

      def diffs(paths = nil)
        # Return empty array if amount of commits
        # more than specified limit
        return [] if commits_over_limit?

        # Try to collect diff only if diffs is empty
        # Otherwise return cached version
        if @diffs.empty? && @timeout == false
          begin
            @diffs = Gitlab::Git::Diff.between(@repository, @head.id, @base.id, *paths)
          rescue Gitlab::Git::Diff::TimeoutError => ex
            @diffs = []
            @timeout = true
          end
        end

        @diffs
      end

      # Check if diff is empty because it is actually empty
      # and not because its impossible to get it
      def empty_diff?
        diffs.empty? && timeout == false && commits.size < limit
      end

      def commits_over_limit?
        commits.size > limit
      end
    end
  end
end
