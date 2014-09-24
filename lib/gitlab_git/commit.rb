# Gitlab::Git::Commit is a wrapper around native Rugged::Commit object
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

      def ==(other)
        return false unless other.is_a?(Gitlab::Git::Commit)

        id == other.id &&
          message == other.message &&
          parent_ids == other.parent_ids &&
          authored_date == other.authored_date &&
          author_name == other.author_name &&
          author_email == other.author_email &&
          committed_date == other.committed_date &&
          committer_name == other.committer_name &&
          committer_email == other.committer_email
      end

      class << self
        # Get commits collection
        #
        # Ex.
        #   Commit.where(
        #     repo: repo,
        #     ref: 'master',
        #     path: 'app/models',
        #     limit: 10,
        #     offset: 5,
        #   )
        #
        def where(options)
          repo = options.delete(:repo)
          raise 'Gitlab::Git::Repository is required' unless repo.respond_to?(:log)

          repo.log(options).map { |c| decorate(c) }
        end

        # Get single commit
        #
        # Ex.
        #   Commit.find(repo, '29eda46b')
        #
        #   Commit.find(repo, 'master')
        #
        def find(repo, commit_id = nil)
          return decorate(commit_id) if commit_id.is_a?(Rugged::Commit)
          rev = commit_id || "HEAD"

          obj = repo.rugged.rev_parse(rev)
          if obj.is_a?(Rugged::Tag::Annotation)
            commit = obj.target
          elsif obj.is_a?(Rugged::Commit)
            commit = obj
          else
            raise("Invalid commit ID")
          end
          decorate(commit) if commit
        rescue Rugged::ReferenceError, Rugged::ObjectError
          nil
        end

        # Get last commit for HEAD
        #
        # Ex.
        #   Commit.last(repo)
        #
        def last(repo)
          find(repo)
        end

        # Get last commit for specified path and ref
        #
        # Ex.
        #   Commit.last_for_path(repo, '29eda46b', 'app/models')
        #
        #   Commit.last_for_path(repo, 'master', 'Gemfile')
        #
        def last_for_path(repo, ref, path = nil)
          where(
            repo: repo,
            ref: ref,
            path: path,
            limit: 1
          ).first
        end

        # Get commits between two refs
        #
        # Ex.
        #   Commit.between('29eda46b', 'master')
        #
        def between(repo, base, head)
          repo.commits_between(base, head).map do |commit|
            decorate(commit)
          end
        rescue Rugged::ReferenceError
          []
        end

        # Delegate Repository#find_commits
        def find_all(repo, options = {})
          repo.find_commits(options)
        end

        def decorate(commit, ref = nil)
          Gitlab::Git::Commit.new(commit, ref)
        end
      end

      def initialize(raw_commit, head = nil)
        raise "Nil as raw commit passed" unless raw_commit

        if raw_commit.is_a?(Hash)
          init_from_hash(raw_commit)
        elsif raw_commit.is_a?(Rugged::Commit)
          init_from_rugged(raw_commit)
        else
          raise "Invalid raw commit type: #{raw_commit.class}"
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

      # Returns a diff object for the changes from this commit's first parent.
      # If there is no parent, then the diff is between this commit and an
      # empty repo.
      def diff_from_parent
        if raw_commit.parents.empty?
          raw_commit.diff(reverse: true)
        else
          raw_commit.parents[0].diff(raw_commit)
        end
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
        diff_from_parent.map { |diff| Gitlab::Git::Diff.new(diff) }
      end

      def parents
        raw_commit.parents.map { |c| Gitlab::Git::Commit.new(c) }
      end

      def tree
        raw_commit.tree
      end

      def stats
        Gitlab::Git::CommitStats.new(self)
      end

      def to_patch
        raw_commit.to_mbox
      end

      # Get a collection of Rugged::Reference objects for this commit.
      #
      # Ex.
      #   commit.ref(repo)
      #
      def refs(repo)
        repo.refs_hash[id]
      end

      # Get ref names collection
      #
      # Ex.
      #   commit.ref_names(repo)
      #
      def ref_names(repo)
        refs(repo).map do |ref|
          ref.name.sub(%r{^refs/(heads|remotes|tags)/}, "")
        end
      end

      private

      def init_from_hash(hash)
        raw_commit = hash.symbolize_keys

        serialize_keys.each do |key|
          send("#{key}=", raw_commit[key])
        end
      end

      def init_from_rugged(commit)
        @raw_commit = commit
        @id = commit.oid
        @message = commit.message
        @authored_date = commit.author[:time]
        @committed_date = commit.committer[:time]
        @author_name = commit.author[:name]
        @author_email = commit.author[:email]
        @committer_name = commit.committer[:name]
        @committer_email = commit.committer[:email]
        @parent_ids = commit.parents.map(&:oid)
      end

      def serialize_keys
        SERIALIZE_KEYS
      end
    end
  end
end
