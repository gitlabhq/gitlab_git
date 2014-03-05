# Gitlab::Git::Diff is a wrapper around native Grit::Diff object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Diff
      class TimeoutError < StandardError; end

      attr_accessor :raw_diff

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Rugged diff mapping
      #
      # diff = {
      #  patches: [
      #   {
      #     additions: Fixnum,
      #     deletions: Fixnum,
      #     context:   Fixnum,
      #     delta: {
      #       old_file: {
      #         path:  String,
      #         mode:  Fixnum,
      #         size:  Fixnum,
      #         flags: Fixnum
      #       },
      #
      #       new_file: {
      #         path:  String,
      #         mode:  Fixnum,
      #         size:  Fixnum,
      #         flags: Fixnum
      #       },
      #       status:   Symbol,
      #       file_type: String
      #     },
      #     hunks: [
      #       {
      #         header: String,
      #         lines: [
      #           {
      #             line_origin: Symbol
      #             content: String,
      #             old_lineno:  Fixnum,
      #             new_lineno:  Fixnum,
      #           }
      #         ]
      #       }
      #     ]
      #   }
      #  ]
      # }


      # Stats properties
      attr_accessor  :new_file, :renamed_file, :deleted_file

      class << self
        def between(repo, head, base, *paths)
          # Only show what is new in the source branch compared to the target branch, not the other way around.
          # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
          # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
          common_commit = repo.merge_base_commit(head, base)

          raw_diff = repo.diff(common_commit, head, *paths)
          if raw_diff.is_a?(Rugged::Diff)
            diff.each_patch do |patch|
              Gitlab::Git::Diff.new(diff)
            end
          else
            raw_diff.map do |diff|
              Gitlab::Git::Diff.new(diff)
            end
          end
        rescue Grit::Git::GitTimeout
          raise TimeoutError.new("Diff.between exited with timeout")
        end
      end

      def initialize(raw_diff)
        raise "Nil as raw diff passed" unless raw_diff

        case raw_diff
        when Hash
          init_from_hash(raw_diff)
        when Rugged::Diff::Patch
          init_from_rugged(raw_diff)
        else
          init_from_grit(raw_diff)
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

      private

      def init_from_rugged(patch)
        @raw_diff = patch

        delta = patch.delta

        @new_file = delta.added?
        @renamed_file = delta.renamed?
        @deleted_file = delta.deleted?

        @old_path = delta.old_file[:path]
        @new_path = delta.new_file[:path]

        @a_mode = '%06o' % delta.old_file[:mode]
        @b_mode = '%06o' % delta.new_file[:mode]

        # @diff = ... 
        #
        # String diff is.... fucking string
        #
        # I think it's bad idea to parse text diff for rendering when we can work with ready to render date in lazy
        # this place broke capability with grit and required many changes in Gitlab diff rendering
        #
        # Example:
        # patch.each_hunk {|h| p h; h.each_line {|l| p l }}
        # =>
        # #<Rugged::Diff::Hunk:-576598398 {header: "@@ -83,6 +83,7 @@ GEM\n", range: {:old_start=>83, :old_lines=>6, :new_start=>83, :new_lines=>7}>
        # #<Rugged::Diff::Line:-576598688 {line_origin: :context, content: "      execjs\n">
        # #<Rugged::Diff::Line:-576598818 {line_origin: :context, content: "    coffee-script-source (1.1.2)\n">
        # #<Rugged::Diff::Line:-576599008 {line_origin: :context, content: "    columnize (0.3.4)\n">
        # #<Rugged::Diff::Line:-576599148 {line_origin: :addition, content: "    daemons (1.1.4)\n">
        # #<Rugged::Diff::Line:-576599268 {line_origin: :context, content: "    database_cleaner (0.6.7)\n">
        # #<Rugged::Diff::Line:-576599388 {line_origin: :context, content: "    devise (1.4.7)\n">
        # #<Rugged::Diff::Line:-576599658 {line_origin: :context, content: "      bcrypt-ruby (~> 3.0)\n">
        # #<Rugged::Diff::Hunk:-576599758 {header: "@@ -90,6 +91,7 @@ GEM\n", range: {:old_start=>90, :old_lines=>6, :new_start=>91, :new_lines=>7}>
        # #<Rugged::Diff::Line:-576600008 {line_origin: :context, content: "      warden (~> 1.0.3)\n">
        # #<Rugged::Diff::Line:-576600118 {line_origin: :context, content: "    diff-lcs (1.1.3)\n">
        # #<Rugged::Diff::Line:-576600288 {line_origin: :context, content: "    erubis (2.7.0)\n">
        # #<Rugged::Diff::Line:-576600388 {line_origin: :addition, content: "    eventmachine (0.12.10)\n">
        # #<Rugged::Diff::Line:-576600528 {line_origin: :context, content: "    execjs (1.2.6)\n">
        # #<Rugged::Diff::Line:-576600658 {line_origin: :context, content: "      multi_json (~> 1.0)\n">
        # #<Rugged::Diff::Line:-576600768 {line_origin: :context, content: "    faker (0.9.5)\n">
        # #<Rugged::Diff::Hunk:-576600968 {header: "@@ -209,6 +211,10 @@ GEM\n", range: {:old_start=>209, :old_lines=>6, :new_start=>211, :new_lines=>10}>
        # #<Rugged::Diff::Line:-576601308 {line_origin: :context, content: "    stamp (0.1.6)\n">
        # #<Rugged::Diff::Line:-576601578 {line_origin: :context, content: "    therubyracer (0.9.4)\n">
        # #<Rugged::Diff::Line:-576601768 {line_origin: :context, content: "      libv8 (~> 3.3.10)\n">
        # #<Rugged::Diff::Line:-576601928 {line_origin: :addition, content: "    thin (1.2.11)\n">
        # #<Rugged::Diff::Line:-576602028 {line_origin: :addition, content: "      daemons (>= 1.0.9)\n">
        # #<Rugged::Diff::Line:-576577648 {line_origin: :addition, content: "      eventmachine (>= 0.12.6)\n">
        # #<Rugged::Diff::Line:-576577768 {line_origin: :addition, content: "      rack (>= 1.0.0)\n">
        # #<Rugged::Diff::Line:-576577908 {line_origin: :context, content: "    thor (0.14.6)\n">
        # #<Rugged::Diff::Line:-576578028 {line_origin: :context, content: "    tilt (1.3.3)\n">
        # #<Rugged::Diff::Line:-576578138 {line_origin: :context, content: "    treetop (1.4.10)\n">
        # #<Rugged::Diff::Hunk:-576578398 {header: "@@ -261,6 +267,7 @@ DEPENDENCIES\n", range: {:old_start=>261, :old_lines=>6, :new_start=>267, :new_lines=>7}>
        # #<Rugged::Diff::Line:-576579378 {line_origin: :context, content: "  sqlite3\n">
        # #<Rugged::Diff::Line:-576579528 {line_origin: :context, content: "  stamp\n">
        # #<Rugged::Diff::Line:-576579658 {line_origin: :context, content: "  therubyracer\n">
        # #<Rugged::Diff::Line:-576579758 {line_origin: :addition, content: "  thin\n">
        # #<Rugged::Diff::Line:-576579898 {line_origin: :context, content: "  turn\n">
        # #<Rugged::Diff::Line:-576580018 {line_origin: :context, content: "  uglifier\n">
        # #<Rugged::Diff::Line:-576580528 {line_origin: :context, content: "  will_paginate (~> 3.0)\n">      end

      def init_from_grit(grit)
        @raw_diff = grit

        serialize_keys.each do |key|
          send(:"#{key}=", grit.send(key))
        end
      end

      def init_from_hash(hash)
        raw_diff = hash.symbolize_keys

        serialize_keys.each do |key|
          send(:"#{key}=", raw_diff[key.to_sym])
        end
      end
    end
  end
end

