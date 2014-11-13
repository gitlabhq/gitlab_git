require 'gitlab_git'
require 'memory_benchmark'

memory_benchmark do
  repo = Gitlab::Git::Repository.new(ARGV.first)
  repo.search_files('baz', '5a90ed56c6270627fe92def4eeca1ef150fc2d4c')
end
