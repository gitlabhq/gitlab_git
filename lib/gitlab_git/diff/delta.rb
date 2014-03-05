module Gitlab
  module Git
    module Diff
      class Delta

        attr_accessor :raw_delta, :store_delta

        attr_accessor :binary, :status, :similarity, :old_file, :new_file

        def initialize(delta)
          @raw_delta = delta

          case delta
          when Hash
            init_from_hash(delta)
            @store_delta = delta
          when Rugged::Diff::Delta
            init_from_rugged(delta)
            @store_delta = to_hash
          end
        end

        def added?
          @status == :added
        end

        def deleted?
          @status == :deleted
        end

        def copied?
          @status == :copied
        end

        def renamed?
          @status == :renamed
        end

        def modified?
          @status == :modified
        end

        def to_hash
          {
            binary: binary,
            status: status,
            similarity: similarity,
            old_file: old_file,
            new_file: new_file
          }
        end

        private

        def init_from_hash(hd)
          @binary     = rd[:binary]
          @status     = rd[:status]
          @similarity = rd[:similarity]
          @old_file   = rd[:old_file]
          @new_file   = rd[:new_file]
        end

        def init_from_rugged(rd)
          @binary     = rd.binary
          @status     = rd.status
          @similarity = rd.similarity
          @old_file   = rd.old_file
          @new_file   = rd.new_file
        end
      end
    end
  end
end
