# Performance tests for gitlab_git

These tests are meant to help developers judge whether code changes improve or
worsen gitlab_git performance. The tests operate on the repository at
https://gitlab.com/gitlab-org/git-memory-test .

## Run all available tests

```
bundle exec rake
```

## List all available tests

```
bundle exec rake -T
```

## Add a new test

Create a `.rb` file in the `test/` directory. Example:

```
require 'gitlab_git'
require 'memory_benchmark'

memory_benchmark do
  repo = Gitlab::Git::Repository.new(ARGV.first)
  repo.do_interesting_stuff
end
```
