# Gitlab::Git::Diff is a wrapper around native Rugged::Diff object
module Gitlab
  module Git
    class Diff
      class TimeoutError < StandardError; end
      include EncodingHelper

      attr_accessor :raw_diff

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Stats properties
      attr_accessor  :new_file, :renamed_file, :deleted_file

      class << self
        def between(repo, head, base, *paths)
          # Only show what is new in the source branch compared to the target branch, not the other way around.
          # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
          # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
          common_commit = repo.merge_base_commit(head, base)

          repo.diff(common_commit, head, *paths)
        end
      end

      def initialize(raw_diff)
        raise "Nil as raw diff passed" unless raw_diff

        if raw_diff.is_a?(Hash)
          init_from_hash(raw_diff)
        elsif raw_diff.is_a?(Rugged::Patch)
          init_from_rugged(raw_diff)
        else
          raise "Invalid raw diff type: #{raw_diff.class}"
        end
      end

      def serialize_keys
        @serialize_keys ||= %w(diff new_path old_path a_mode b_mode new_file renamed_file deleted_file).map(&:to_sym)
      end

      def to_hash
        hash = {}

        keys = serialize_keys

        keys.each do |key|
          hash[key] = send(key)
        end

        hash
      end

      def submodule?
        a_mode == '160000' || b_mode == '160000'
      end

      private

      def init_from_rugged(rugged)
        @raw_diff = rugged

        @diff = encode!(strip_diff_headers(rugged.to_s))

        d = rugged.delta
        @new_path = encode!(d.new_file[:path])
        @old_path = encode!(d.old_file[:path])
        @a_mode = d.old_file[:mode].to_s(8)
        @b_mode = d.new_file[:mode].to_s(8)
        @new_file = d.added?
        @renamed_file = d.renamed?
        @deleted_file = d.deleted?
      end

      def init_from_hash(hash)
        raw_diff = hash.symbolize_keys

        serialize_keys.each do |key|
          send(:"#{key}=", raw_diff[key.to_sym])
        end
      end

      # Strip out the information at the beginning of the patch's text to match
      # Grit's output
      def strip_diff_headers(diff_text)
        result = diff_text.sub!(/\A.*?^(---|Binary)/m, '\1').chomp!
        if result.start_with?('---') or result.start_with?('Binary')
          result
        else
          ''
        end
      end
    end
  end
end

