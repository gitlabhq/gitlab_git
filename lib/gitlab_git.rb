# Libraries
require 'ostruct'
require 'fileutils'
require 'grit'
require 'linguist'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/try'
require 'grit'
require 'grit_ext'
require 'rugged'
require "charlock_holmes"

Grit::Blob.class_eval do
  include Linguist::BlobHelper
end

# Gitlab::Git
require_relative "gitlab_git/popen"
require_relative "gitlab_git/encoding_herlper"
require_relative "gitlab_git/blame"
require_relative "gitlab_git/blob"
require_relative "gitlab_git/commit"
require_relative "gitlab_git/compare"
require_relative "gitlab_git/diff"
require_relative "gitlab_git/diffs/delta"
require_relative "gitlab_git/diffs/hunk"
require_relative "gitlab_git/diffs/line"
require_relative "gitlab_git/diffs/patch"
require_relative "gitlab_git/repository"
require_relative "gitlab_git/stats"
require_relative "gitlab_git/tree"
require_relative "gitlab_git/blob_snippet"
require_relative "gitlab_git/git_stats"
require_relative "gitlab_git/log_parser"
require_relative "gitlab_git/ref"
require_relative "gitlab_git/branch"
require_relative "gitlab_git/tag"
