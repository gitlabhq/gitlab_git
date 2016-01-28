require_relative 'encoding_helper'
require_relative 'path_helper'

module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper
      include EncodingHelper

      # This number needs to be large enough to allow reliable content /
      # encoding detection (Linguist) and LFS pointer parsing. All other cases
      # where we need full blob data should use load_all_data!.
      DATA_SNIPPET_SIZE = 8192

      attr_accessor :name, :path, :size, :data, :mode, :id, :commit_id

      class << self
        def find(repository, sha, path)
          commit = repository.lookup(sha)
          root_tree = commit.tree

          blob_entry = find_entry_by_path(repository, root_tree.oid, path)

          return nil unless blob_entry

          if blob_entry[:type] == :commit
            submodule_blob(blob_entry, path, sha)
          else
            blob = repository.lookup(blob_entry[:oid])

            if blob
              Blob.new(
                id: blob.oid,
                name: blob_entry[:name],
                size: blob.size,
                data: blob.content(DATA_SNIPPET_SIZE),
                mode: blob_entry[:filemode].to_s(8),
                path: path,
                commit_id: sha,
              )
            end
          end
        end

        def raw(repository, sha)
          blob = repository.lookup(sha)

          Blob.new(
            id: blob.oid,
            size: blob.size,
            data: blob.content(DATA_SNIPPET_SIZE),
          )
        end

        # Recursive search of blob id by path
        #
        # Ex.
        #   blog/            # oid: 1a
        #     app/           # oid: 2a
        #       models/      # oid: 3a
        #       file.rb      # oid: 4a
        #
        #
        # Blob.find_entry_by_path(repo, '1a', 'app/file.rb') # => '4a'
        #
        def find_entry_by_path(repository, root_id, path)
          root_tree = repository.lookup(root_id)
          # Strip leading slashes
          path[/^\/*/] = ''
          path_arr = path.split('/')

          entry = root_tree.find do |entry|
            entry[:name] == path_arr[0]
          end

          return nil unless entry

          if path_arr.size > 1
            return nil unless entry[:type] == :tree
            path_arr.shift
            find_entry_by_path(repository, entry[:oid], path_arr.join('/'))
          else
            [:blob, :commit].include?(entry[:type]) ? entry : nil
          end
        end

        def submodule_blob(blob_entry, path, sha)
          Blob.new(
            id: blob_entry[:oid],
            name: blob_entry[:name],
            data: '',
            path: path,
            commit_id: sha,
          )
        end

        # Commit file in repository and return commit sha
        #
        # options should contain next structure:
        #   file: {
        #     content: 'Lorem ipsum...',
        #     path: 'documents/story.txt',
        #     update: true
        #   },
        #   author: {
        #     email: 'user@example.com',
        #     name: 'Test User',
        #     time: Time.now
        #   },
        #   committer: {
        #     email: 'user@example.com',
        #     name: 'Test User',
        #     time: Time.now
        #   },
        #   commit: {
        #     message: 'Wow such commit',
        #     branch: 'master'
        #   }
        #
        def commit(repository, options, action = :add)
          file = options[:file]
          update = file[:update].nil? ? true : file[:update]
          author = options[:author]
          committer = options[:committer]
          commit = options[:commit]
          repo = repository.rugged
          ref = commit[:branch]
          parents = []

          unless ref.start_with?('refs/')
            ref = 'refs/heads/' + ref
          end

          path_name = PathHelper.normalize_path(file[:path])
          # Abort if any invalid characters remain (e.g. ../foo)
          raise Repository::InvalidBlobName.new("Invalid path") if path_name.each_filename.to_a.include?('..')

          filename = path_name.to_s
          index = repo.index

          unless repo.empty?
            rugged_ref = repo.references[ref]
            raise Repository::InvalidRef.new("Invalid branch name") unless rugged_ref
            last_commit = rugged_ref.target
            index.read_tree(last_commit.tree)
            parents = [last_commit]
          end

          if action == :remove
            index.remove(filename)
          else
            mode = 0100644
            file_entry = index.get(filename)

            if file_entry
              raise Repository::InvalidBlobName.new("Filename already exists; update not allowed") unless update
              # Preserve the current file mode if one is available
              mode = file_entry[:mode] if file_entry[:mode]
            end

            content = file[:content]
            detect = CharlockHolmes::EncodingDetector.new.detect(content) if content

            unless detect && detect[:type] == :binary
              # When writing to the repo directly as we are doing here,
              # the `core.autocrlf` config isn't taken into account.
              content.gsub!("\r\n", "\n") if repository.autocrlf
            end

            oid = repo.write(content, :blob)
            index.add(path: filename, oid: oid, mode: mode)
          end

          opts = {}
          opts[:tree] = index.write_tree(repo)
          opts[:author] = author
          opts[:committer] = committer
          opts[:message] = commit[:message]
          opts[:parents] = parents
          opts[:update_ref] = ref

          Rugged::Commit.create(repo, opts)
        end

        # Remove file from repository and return commit sha
        #
        # options should contain next structure:
        #   file: {
        #     path: 'documents/story.txt'
        #   },
        #   author: {
        #     email: 'user@example.com',
        #     name: 'Test User',
        #     time: Time.now
        #   },
        #   committer: {
        #     email: 'user@example.com',
        #     name: 'Test User',
        #     time: Time.now
        #   },
        #   commit: {
        #     message: 'Remove FILENAME',
        #     branch: 'master'
        #   }
        #
        def remove(repository, options)
          commit(repository, options, :remove)
        end
      end

      def initialize(options)
        %w(id name path size data mode commit_id).each do |key|
          self.send("#{key}=", options[key.to_sym])
        end
      end

      def empty?
        !data || data == ''
      end

      def data
        encode! @data
      end

      # Load all blob data (not just the first DATA_SNIPPET_SIZE bytes) into
      # memory as a Ruby string.
      def load_all_data!(repository)
        @data = repository.lookup(id).content
      end

      def name
        encode! @name
      end

      # Valid LFS object pointer is a text file consisting of
      # version
      # oid
      # size
      # see https://github.com/github/git-lfs/blob/v1.1.0/docs/spec.md#the-pointer
      def lfs_pointer?
        has_lfs_version_key? && lfs_oid.present? && lfs_size.present?
      end

      def lfs_oid
        if has_lfs_version_key?
          oid = data.match(/(?<=sha256:)([0-9a-f]{64})/)
          return oid[1] if oid
        end

        nil
      end

      def lfs_size
        if has_lfs_version_key?
          size = data.match(/(?<=size )([0-9]+)/)
          return size[1] if size
        end

        nil
      end

      private

      def has_lfs_version_key?
        !empty? && text? && data.start_with?("version https://git-lfs.github.com/spec")
      end
    end
  end
end
