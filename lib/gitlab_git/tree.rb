module Gitlab
  module Git
    class Tree
      attr_accessor :id, :root_id, :name, :path, :type,
        :mode, :commit_id, :submodule_url

      class << self
        def where(repository, sha, path = nil)
          path = nil if path == '' || path == '/'

          commit = repository.rugged.lookup(sha)
          root_tree = commit.tree

          tree = if path
                   id = Tree.find_id_by_path(root_tree, path)
                   if id
                     repository.rugged.lookup(id)
                   else
                     []
                   end
                 else
                   root_tree
                 end

          tree.map do |entry|
            Tree.new(
              id: entry[:oid],
              root_id: root_tree.oid,
              name: entry[:name],
              type: entry[:type] || :submodule,
              mode: entry[:filemode],
              path: path ? File.join(path, entry[:name]) : entry[:name],
              commit_id: sha,
            )
          end
        end

        def find_id_by_path(root_tree, path)
          path_arr = path.split('/')

          entry = root_tree.find do |entry|
            entry[:name] == path_arr[0] && entry[:type] == :tree
          end

          return nil unless entry

          if path_arr.size > 1
            path_arr.shift
            tree = repository.rugged.lookup(entry[:oid])
            find_id_by_path(tree, path_arr.join('/'))
          else
            entry[:oid]
          end
        end
      end

      def initialize(options)
        %w(id root_id name path type mode commit_id).each do |key|
          self.send("#{key}=", options[key.to_sym])
        end
      end

      def dir?
        type == :tree
      end

      def file?
        type == :blob
      end

      def submodule?
        type == :submodule
      end

      def readme?
        name =~ /^readme/i
      end
    end
  end
end

