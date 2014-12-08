require 'gitlab_git'
require 'memory_benchmark'

memory_benchmark do
  repo = Gitlab::Git::Repository.new(ARGV.first)
  compare = Gitlab::Git::Compare.new(repo, 'c402afd735002022afc88c61984bba36305d6d20', '5525ad494c3e7b58decc3a810e7b4a70904dd2e3')
  compare.diffs
end
