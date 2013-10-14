module Gitlab
  module Git
    class Tree
      attr_accessor :id, :name, :path, :type, :mode, :commit_id, :submodule_url

      class << self
        def where(repository, sha, path = '/')
          commit = Commit.find(repository, sha)
          grit_tree = commit.tree / path

          if grit_tree && grit_tree.respond_to?(:contents)
            grit_tree.contents.map do |entry|
              type = entry.class.to_s.split("::").last.downcase.to_sym

              Tree.new(
                id: entry.id,
                name: entry.name,
                type: type,
                mode: entry.mode,
                path: path == '/' ? entry.name : File.join(path, entry.name),
                commit_id: sha,
                submodule_url: (type == :submodule) ? entry.url(sha) : nil
              )
            end
          else
            []
          end
        end
      end

      def initialize(options)
        %w(id name path type mode commit_id submodule_url).each do |key|
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

