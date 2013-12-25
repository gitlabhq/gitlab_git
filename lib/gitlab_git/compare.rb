module Gitlab
  module Git
    class Compare
      attr_accessor :commits, :commit, :diffs, :same

      def initialize(repository, from, to, limit = 100)
        @commits, @diffs = [], []
        @commit = nil
        @same = false
        @limit = limit
        @repository = repository

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
        return [] if @commits.size > @limit
        Gitlab::Git::Diff.between(@repository, @head.id, @base.id, *paths) rescue []
      end
    end
  end
end

