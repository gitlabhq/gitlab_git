module Gitlab
  module Git
    module Diffs
      class Hunk

        attr_accessor :raw_hunk

        attr_accessor :header, :lines

        def initialize(hunk)
          @raw_hunk = hunk

          case hunk
          when Hash
            init_from_hash(hunk)
          when Rugged::Diff::Hunk
            init_from_rugged(hunk)
          end
        end

        def line_count
          @lines.count
        end

        def to_hash
          {
            header: header,
            lines: lines_hash
          }
        end

        private

        def init_from_hash(hh)
          @header = hh[:header]
          @lines  = hh[:lines].map { |line| Gitlab::Git::Diffs::Line.new(line) }
        end

        def init_from_rugged(rh)
          @header = rh.header
          @lines  = rh.lines.map { |line| Gitlab::Git::Diffs::Line.new(line) }
        end

        def lines_hash
          lines.reduce([]) {|mem, line| mem.push(line.to_hash) }
        end
      end
    end
  end
end
