module Gitlab
  module Git
    module Diff
      class Patch

        attr_accessor :raw_patch, :store_patch

        attr_accessor :additions, :deletions, :context, :delta, :hunks

        def initialize(patch)
          @raw_patch = patch

          case patch
          when Hash
            init_from_hash(patch)
            @store_patch = patch
          when Rugged::Diff::Patch
            init_from_rugged(patch)
            @store_patch = to_hash
          end
        end

        def changes
          @deletions + @additions
        end

        def to_hash
          {
            additions: additions,
            deletions: deletions,
            context: context,
            delta: delta_hash,
            hunks: hunks_hash
          }
        end

        private

        def init_from_hash(hp)
          @additions = hp[:additions]
          @deletions = hp[:deletions]
          @context   = hp[:context]
          @delta     = Gitlab::Git::Diff::Delta.new(hp[:delta])
          @hunks     = hp[:hunks].map { |hunk| Gitlab::Git::Diff::Hunk.new(hunk) }
        end

        def init_from_rugged(rp)
          @additions = rp.additions
          @deletions = rp.deletions
          @context   = rp.context
          @delta     = Gitlab::Git::Diff::Delta.new(rp.delta)
          @hunks     = rp.hunks.map { |hunk| Gitlab::Git::Diff::Hunk.new(hunk) }
        end

        def delta_hash
          delta.to_hash
        end

        def hunks_hash
          hunks.reduce([]) { |mem, hunk| hunk.to_hash }
        end
      end
    end
  end
end
