module Gitlab
  module Git
    class Blame
      attr_accessor :blob

      def initialize(repository, sha, path)
        @repo = repository.rugged
        @blame = Rugged::Blame.new(@repo, path, { newest_commit: sha })
        @blob = Blob.find(repository, sha, path)
        @lines = @blob.data.split("\n")
      end

      def each
        @blame.each do |blame|
          from = blame[:final_start_line_number] - 1
          commit = @repo.lookup(blame[:final_commit_id])

          yield(Gitlab::Git::Commit.new(commit),
              @lines[from, blame[:lines_in_hunk]] || [],
              blame[:final_start_line_number])
        end
      end
    end
  end
end
