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
        index = repo.rugged.index
        index.read_tree(repo.rugged.head.target.tree)
        index.count
      end

      def authors_count
        authors.size
      end

      def graph
        @graph ||= build_graph
      end

      protected

      def collect_authors
        commits = repo.log(ref: ref, limit: 0)

        author_stats = {}
        commits.each do |commit|
          if author_stats.key?(commit.author[:name])
            author_stats[commit.author[:name]][:count] += 1
          else
            author_stats[commit.author[:name]] = {
              email: commit.author[:email],
              count: 1
            }
          end
        end

        authors = []
        author_stats.each do |author_name, info|
          authors << OpenStruct.new(
            name: author_name,
            email: info[:email],
            commits: info[:count]
          )
        end

        authors.sort_by(&:commits).reverse
      end

      def build_graph(n = 4)
        from, to = (Date.today.prev_day(n*7)), Date.today
        rev_list = repo.commits_since(from)

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
