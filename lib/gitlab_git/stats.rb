module Gitlab
  module Git
    class Stats
      attr_accessor :repo, :ref

      def initialize repo, ref
        @repo, @ref = repo, ref
      end

      def authors
        @authors ||= collect_authors
      end

      def commits_count
        @commits_count ||= repo.commit_count(ref)
      end

      def files_count
        args = [ref, '-r', '--name-only' ]
        repo.git.native(:ls_tree, {}, args).split("\n").count
      end

      def authors_count
        authors.size
      end

      def graph
        @graph ||= build_graph
      end

      protected

      def collect_authors
        shortlog = repo.git.shortlog({e: true, s: true }, ref)

        authors = []

        lines = shortlog.split("\n")

        lines.each do |line|
          data = line.split("\t")
          commits = data.first
          author = Grit::Actor.from_string(data.last)

          authors << OpenStruct.new(
            name: author.name,
            email: author.email,
            commits: commits.to_i
          )
        end

        authors.sort_by(&:commits).reverse
      end

      def build_graph(n = 4)
        from, to = (Date.today.prev_day(n*7)), Date.today
        args = ['--all', "--since=#{from.to_s}", '--format=%ad' ]
        rev_list = repo.git.native(:rev_list, {}, args).split("\n")

        commits_dates = rev_list.values_at(* rev_list.each_index.select {|i| i.odd?})
        commits_dates = commits_dates.map { |date_str| Time.parse(date_str).to_date.to_s }

        commits_per_day = from.upto(to).map do |day|
          commits_dates.count(day.to_date.to_s)
        end

        OpenStruct.new(
          labels: from.upto(to).map { |day| day.strftime('%b %d') },
          commits: commits_per_day,
          weeks: n
        )
      end
    end
  end
end
