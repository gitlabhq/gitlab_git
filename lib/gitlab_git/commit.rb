# Gitlab::Git::Commit is a wrapper around native Grit::Commit object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Commit
      attr_accessor :raw_commit, :head, :refs

      SERIALIZE_KEYS = [
        :id, :message, :parent_ids,
        :authored_date, :author_name, :author_email,
        :committed_date, :committer_name, :committer_email
      ]
      attr_accessor *SERIALIZE_KEYS

      def initialize(raw_commit, head = nil)
        raise "Nil as raw commit passed" unless raw_commit

        if raw_commit.is_a?(Hash)
          init_from_hash(raw_commit)
        else
          init_from_grit(raw_commit)
        end

        @head = head
      end

      def sha
        id
      end

      def short_id(length = 10)
        id.to_s[0..length]
      end

      def safe_message
        @safe_message ||= message
      end

      def created_at
        committed_date
      end

      # Was this commit committed by a different person than the original author?
      def different_committer?
        author_name != committer_name || author_email != committer_email
      end

      def parent_id
        parent_ids.first
      end

      # Shows the diff between the commit's parent and the commit.
      #
      # Cuts out the header and stats from #to_patch and returns only the diff.
      def to_diff
        # see Grit::Commit#show
        patch = to_patch

        # discard lines before the diff
        lines = patch.split("\n")
        while !lines.first.start_with?("diff --git") do
          lines.shift
        end
        lines.pop if lines.last =~ /^[\d.]+$/ # Git version
        lines.pop if lines.last == "-- "      # end of diff
        lines.join("\n")
      end

      def has_zero_stats?
        stats.total.zero?
      rescue
        true
      end

      def no_commit_message
        "--no commit message"
      end

      def to_hash
        serialize_keys.map.with_object({}) do |key, hash|
          hash[key] = send(key)
        end
      end

      def date
        committed_date
      end

      def diffs
        raw_commit.diffs.map { |diff| Gitlab::Git::Diff.new(diff) }
      end

      def parents
        raw_commit.parents
      end

      def tree
        raw_commit.tree
      end

      def stats
        raw_commit.stats
      end

      def to_patch
        raw_commit.to_patch
      end

      private

      def init_from_grit(grit)
        @raw_commit = grit
        @id = grit.id
        @message = grit.message
        @authored_date = grit.authored_date
        @committed_date = grit.committed_date
        @author_name = grit.author.name
        @author_email = grit.author.email
        @committer_name = grit.committer.name
        @committer_email = grit.committer.email
        @parent_ids = grit.parents.map(&:id)
      end

      def init_from_hash(hash)
        raw_commit = hash.symbolize_keys

        serialize_keys.each do |key|
          send("#{key}=", raw_commit[key])
        end
      end

      def serialize_keys
        SERIALIZE_KEYS
      end
    end
  end
end
