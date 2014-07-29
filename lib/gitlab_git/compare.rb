module Gitlab
  module Git
    class Compare
      attr_reader :commits, :diffs, :same, :timeout, :head, :base

      def initialize(repository, base, head)
        @commits, @diffs = [], []
        @same = false
        @repository = repository
        @timeout = false

        return unless base && head

        @base = Gitlab::Git::Commit.find(repository, base.try(:strip))
        @head = Gitlab::Git::Commit.find(repository, head.try(:strip))

        return unless @base && @head

        if @base.id == @head.id
          @same = true
          return
        end

        @commits = Gitlab::Git::Commit.between(repository, @base.id, @head.id)
      end

      def diffs(paths = nil)
        unless @head && @base
          return []
        end

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
        diffs.empty? && timeout == false
      end
    end
  end
end
