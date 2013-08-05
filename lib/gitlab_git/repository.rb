# Gitlab::Git::Gitlab::Git::Commit is a wrapper around native Grit::Repository object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Repository
      include Gitlab::Git::Popen

      class NoRepository < StandardError; end

      class << self
        attr_accessor :repos_path
      end

      # Repository directory name with namespace direcotry
      # Examples:
      #   gitlab/gitolite
      #   diaspora
      #
      attr_accessor :path_with_namespace

      # Grit repo object
      attr_accessor :repo

      # Default branch in the repository
      attr_accessor :root_ref

      def initialize(path_with_namespace, root_ref = 'master')
        @root_ref = root_ref || "master"
        @path_with_namespace = path_with_namespace

        # Init grit repo object
        repo
      end

      def raw
        repo
      end

      def path_to_repo
        @path_to_repo ||= File.join(repos_path, "#{path_with_namespace}.git")
      end

      def repos_path
        self.class.repos_path
      end

      def repo
        @repo ||= Grit::Repo.new(path_to_repo)
      rescue Grit::NoSuchPathError
        raise NoRepository.new('no repository for such path')
      end

      # Returns an Array of branch names
      # sorted by name ASC
      def branch_names
        branches.map(&:name)
      end

      # Returns an Array of Branches
      def branches
        repo.branches.sort_by(&:name)
      end

      # Returns an Array of tag names
      def tag_names
        tags.map(&:name)
      end

      # Returns an Array of Tags
      def tags
        repo.tags.sort_by(&:name).reverse
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def heads
        @heads ||= repo.heads.sort_by(&:name)
      end

      def tree(fcommit, path = nil)
        fcommit = commit if fcommit == :head
        tree = fcommit.tree
        path ? (tree / path) : tree
      end

      def has_commits?
        !!Gitlab::Git::Commit.last(self)
      rescue Grit::NoSuchPathError
        false
      end

      def empty?
        !has_commits?
      end

      # Discovers the default branch based on the repository's available branches
      #
      # - If no branches are present, returns nil
      # - If one branch is present, returns its name
      # - If two or more branches are present, returns the one that has a name
      #   matching root_ref (default_branch or 'master' if default_branch is nil)
      def discover_default_branch
        if branch_names.length == 0
          nil
        elsif branch_names.length == 1
          branch_names.first
        else
          branch_names.select { |v| v == root_ref }.first
        end
      end

      # Archive Project to .tar.gz
      #
      # Already packed repo archives stored at
      # app_root/tmp/repositories/project_name/project_name-commit-id.tag.gz
      #
      def archive_repo(ref, storage_path)
        ref = ref || self.root_ref
        commit = Gitlab::Git::Commit.find(self, ref)
        return nil unless commit

        # Build file path
        file_name = self.path_with_namespace.gsub("/","_") + "-" + commit.id.to_s + ".tar.gz"
        file_path = File.join(storage_path, self.path_with_namespace, file_name)

        # Put files into a directory before archiving
        prefix = File.basename(self.path_with_namespace) + "/"

        # Create file if not exists
        unless File.exists?(file_path)
          FileUtils.mkdir_p File.dirname(file_path)
          file = self.repo.archive_to_file(ref, prefix,  file_path)
        end

        file_path
      end

      # Return repo size in megabytes
      def size
        size = popen('du -s', path_to_repo).first.strip.to_i
        (size.to_f / 1024).round(2)
      end

      def diffs_between(source_branch, target_branch)
        # Only show what is new in the source branch compared to the target branch, not the other way around.
        # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
        # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
        common_commit = repo.git.native(:merge_base, {}, [target_branch, source_branch]).strip
        repo.diff(common_commit, source_branch).map { |diff| Gitlab::Git::Diff.new(diff) }

      rescue Grit::Git::GitTimeout
        [Gitlab::Git::Diff::BROKEN_DIFF]
      end

      def search_files(query, ref = nil)
        if ref.nil? || ref == ""
          ref = root_ref
        end

        greps = repo.grep(query, 3, ref)

        greps.map do |grep|
          Gitlab::Git::BlobSnippet.new(ref, grep.content, grep.startline, grep.filename)
        end
      end

      # Delegate log to Grit method
      #
      # Usage.
      #   repo.log(
      #     ref: 'master',
      #     path: 'app/models',
      #     limit: 10,
      #     offset: 5,
      #   )
      #
      def log(options)
        default_options = {
          limit: 10,
          offset: 0,
          path: nil,
          ref: root_ref,
          follow: false
        }

        options = default_options.merge(options)

        repo.log(
          options[:ref] || root_ref,
          options[:path],
          max_count: options[:limit].to_i,
          skip: options[:offset].to_i,
          follow: options[:follow]
        )
      end

      # Delegate commits_between to Grit method
      #
      def commits_between(from, to)
        repo.commits_between(from, to)
      end
    end
  end
end
