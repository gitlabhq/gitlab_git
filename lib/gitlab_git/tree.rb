module Gitlab
  module Git
    class Tree
      attr_accessor :repository, :sha, :path, :ref, :raw_tree, :id

      def initialize(repository, sha, ref = nil, path = nil)
        @repository, @sha, @ref, @path = repository, sha, ref, path

        @path = nil if !@path || @path == ''

        # Load tree from repository
        @commit = @repository.commit(@sha)
        @raw_tree = @repository.tree(@commit, @path)
      end

      def exists?
        raw_tree
      end

      def empty?
        trees.empty? && blobs.empty?
      end

      def trees
        entries.select { |t| t.is_a?(Grit::Tree) }
      end

      def blobs
        entries.select { |t| t.is_a?(Grit::Blob) }
      end

      def is_blob?
        raw_tree.is_a?(Grit::Blob)
      end

      def up_dir?
        path && path != ''
      end

      def readme
        @readme ||= blobs.find { |c| c.name =~ /^readme/i }
      end

      protected

      def entries
        raw_tree.contents
      end
    end
  end
end

