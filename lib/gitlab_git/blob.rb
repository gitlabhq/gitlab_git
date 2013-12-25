module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper

      attr_accessor :name, :path, :size, :data, :mode, :id, :commit_id

      class << self
        def find(repository, sha, path)
          commit = Commit.find(repository, sha)
          grit_blob = commit.tree / path

          if grit_blob.kind_of?(Grit::Blob)
            Blob.new(
              id: grit_blob.id,
              name: grit_blob.name,
              size: grit_blob.size,
              data: grit_blob.data,
              mode: grit_blob.mode,
              path: path,
              commit_id: sha,
            )
          end
        end

        def raw(repository, sha)
          grit_blob = repository.grit.blob(sha)
          Blob.new(
            id: grit_blob.id,
            size: grit_blob.size,
            data: grit_blob.data,
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
    end
  end
end
