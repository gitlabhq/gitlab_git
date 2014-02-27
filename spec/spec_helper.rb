if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
else
  require 'simplecov'
  SimpleCov.start
end

require 'gitlab_git'
require 'pry'

require_relative 'support/seed_helper'
require_relative 'support/commit'
require_relative 'support/first_commit'
require_relative 'support/last_commit'
require_relative 'support/big_commit'

RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual != nil
    actual.id == SeedRepo::Commit::ID
    actual.message == SeedRepo::Commit::MESSAGE
    actual.author_name == SeedRepo::Commit::AUTHOR_FULL_NAME
  end
end

SUPPORT_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '../support')
TEST_REPO_PATH = File.join(SUPPORT_PATH, 'testme.git')

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  config.include SeedHelper
  config.before(:all) { ensure_seeds }
end
