module Gitlab
  module Git
    module Diffs
      class Line

        attr_accessor :raw_line

        attr_accessor :line_origin, :content, :new_lineno, :old_lineno

        def initialize(line)
          @raw_line = line

          case line
          when Hash
            init_from_hash(line)
          when Rugged::Diff::Line
            init_from_rugged(line)
          end
        end

        def to_hash
          {
            line_origin: line_origin,
            content: content,
            new_lineno: new_lineno,
            old_lineno: old_lineno
          }
        end

        def addition?
          @line_origin == :addition
        end

        def context?
          @line_origin == :context
        end

        def deletion?
          @line_origin == :deletion
        end

        def eof_newline?
          @line_origin == :eof_newline
        end

        def inspect
            "#<#{self.class.name}:#{object_id} {line_origin: #{line_origin.inspect}, content: #{content.inspect}>"
        end

        private

        def init_from_hash(line)
          @line_origin = line[:line_origin]
          @content     = line[:content]
          @new_lineno  = line[:new_lineno]
          @old_lineno  = line[:old_lineno]
        end

        def init_from_rugged(line)
          @line_origin = line.line_origin
          @content     = line.content
          @new_lineno  = line.new_lineno
          @old_lineno  = line.old_lineno
        end
      end
    end
  end
end
