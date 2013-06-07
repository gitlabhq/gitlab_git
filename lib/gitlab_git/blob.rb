module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper

      attr_accessor :raw_blob

      def initialize(repository, sha, ref, path)
        @repository, @sha, @ref = repository, sha, ref

        @commit = @repository.commit(sha)
        @raw_blob = @repository.tree(@commit, path)
      end

      def data
        if raw_blob and raw_blob.respond_to?('data')
          raw_blob.data
        else
          nil
        end
      end

      def name
        raw_blob.name
      end

      def exists?
        raw_blob
      end

      def empty?
        !data || data == ''
      end

      def mode
        raw_blob.mode
      end

      def size
        raw_blob.size
      end
    end
  end
end
