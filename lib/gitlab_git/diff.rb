# Gitlab::Git::Diff is a wrapper around native Grit::Diff object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Diff
      class TimeoutError < StandardError; end

      attr_accessor :raw_diff

      attr_accessor :patches

      class << self
        def between(repo, head, base, *paths)
          # Only show what is new in the source branch compared to the target branch, not the other way around.
          # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
          # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
          common_commit = repo.merge_base_commit(head, base)
          raw_diff = repo.diff(common_commit, head, *paths)

          Gitlab::Git::Diff.new(raw_diff)
        rescue
          raise TimeoutError.new("Diff.between exited with timeout")
        end
      end

      def initialize(raw_diff)
        raise "Nil as raw diff passed" unless raw_diff

        @raw_diff = raw_diff

        case raw_diff
        when Hash
          init_from_hash(raw_diff)
        when Rugged::Diff
          init_from_rugged(raw_diff)
        else
          raise "We don't known how parse raw diff"
        end
      end

      def to_hash
        {
          patches: patches.reduce([]) { |mem, patch| mem.push(patch.to_hash) }
        }
      end

      private

      def init_from_rugged(diff)
        @patches = diff.patches.map { |patch| Gitlab::Git::Diffs::Patch.new(patch) }
      end

      def init_from_hash(hash)
        @patches = hash[:patches].map { |patch| Gitlab::Git::Diffs::Patch.new(patch) }
      end
    end
  end
end
