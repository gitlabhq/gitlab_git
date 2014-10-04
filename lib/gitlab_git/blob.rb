module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper
      include EncodingHelper

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
                data: blob.content,
                mode: blob_entry[:filemode],
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
            data: blob.content,
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

      def name
        encode! @name
      end
    end
  end
end
