# Gitlab::Git::Commit is a wrapper around native Grit::Repository object
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

      # Default branch in the repository
      attr_accessor :root_ref

      # Grit repo object
      attr_reader :raw

      # compatibility
      alias_method :repo, :raw

      def initialize(path_with_namespace, root_ref)
        @root_ref = root_ref || raw.head.name
        @path_with_namespace = path_with_namespace

        # Init grit repo object
        raw
      end

      def path_to_repo
        @path_to_repo ||= File.join(repos_path, "#{path_with_namespace}.git")
      end

      def repos_path
        self.class.repos_path
      end

      def raw
        @raw ||= Grit::Repo.new(path_to_repo)
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
        raw.branches.sort_by(&:name)
      end

      # Returns an Array of tag names
      def tag_names
        tags.map(&:name)
      end

      # Returns an Array of Tags
      def tags
        raw.tags.sort_by(&:name).reverse
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def heads
        @heads ||= raw.heads.sort_by(&:name)
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
          file = self.raw.archive_to_file(ref, prefix,  file_path)
        end

        file_path
      end

      # Return repo size in megabytes
      def size
        size = popen('du -s', path_to_repo).first.strip.to_i
        (size.to_f / 1024).round(2)
      end

      def search_files(query, ref = nil)
        if ref.nil? || ref == ""
          ref = root_ref
        end

        greps = raw.grep(query, 3, ref)

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

        raw.log(
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
        raw.commits_between(from, to)
      end

      def merge_base_commit(from, to)
        raw.git.native(:merge_base, {}, [to, from]).strip
      end

      def diff(from, to)
        raw.diff(from, to)
      end

      # Returns commits collection
      #
      # Ex.
      #   repo.find_commits(
      #     ref: 'master',
      #     max_count: 10,
      #     skip: 5,
      #     order: :date
      #   )
      #
      #   +options+ is a Hash of optional arguments to git
      #     :ref is the ref from which to begin (SHA1 or name)
      #     :contains is the commit contained by the refs from which to begin (SHA1 or name)
      #     :max_count is the maximum number of commits to fetch
      #     :skip is the number of commits to skip
      #     :order is the commits order and allowed value is :date(default) or :topo
      #
      def find_commits(options = {})
        actual_options = options.dup

        allowed_options = [:ref, :max_count, :skip, :contains, :order]

        actual_options.keep_if do |key, value|
          allowed_options.include?(key)
        end

        default_options = {pretty: 'raw', order: :date}

        actual_options = default_options.merge(actual_options)

        order = actual_options.delete(:order)

        case order
        when :date
          actual_options[:date_order] = true
        when :topo
          actual_options[:topo_order] = true
        end

        ref = actual_options.delete(:ref)

        containing_commit = actual_options.delete(:contains)

        args = []

        if ref
          args.push(ref)
        elsif containing_commit
          args.push(*branch_names_contains(containing_commit))
        else
          actual_options[:all] = true
        end

        output = raw.git.native(:rev_list, actual_options, *args)

        Grit::Commit.list_from_string(raw, output).map do |commit|
          Gitlab::Git::Commit.decorate(commit)
        end
      rescue Grit::GitRuby::Repository::NoSuchShaFound
        []
      end

      # Returns branch names collection that contains the special commit(SHA1 or name)
      #
      # Ex.
      #   repo.branch_names_contains('master')
      #
      def branch_names_contains(commit)
        output = raw.git.native(:branch, {contains: true}, commit)
        # The output is expected as follow
        #   fix-aaa
        #   fix-bbb
        # * master
        output.scan(/[^* \n]+/)
      end

      # Get refs hash which key is SHA1 and value is ref object(Grit::Head or Grit::Remote or Grit::Tag)
      def refs_hash
        # Initialize only when first call
        if @refs_hash.nil?
          @refs_hash = Hash.new { |h, k| h[k] = [] }

          @raw.refs.each do |r|
            @refs_hash[r.commit.id] << r
          end
        end

        @refs_hash
      end
    end
  end
end
