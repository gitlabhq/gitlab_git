### GitLab Git

GitLab wrapper around git objects. Use patched Grit as main library for parsing git objects

#### Code status

* [![Build Status](https://travis-ci.org/gitlabhq/gitlab_git.png?branch=master)](https://travis-ci.org/gitlabhq/gitlab_git)
* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab_git.png)](https://codeclimate.com/github/gitlabhq/gitlab_git)
* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlab_git/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlab_git)


### How to use: 

#### Before

Set repositories storage:

    Gitlab::Git::Repository.repos_path = '/home/git/repositories'

#### Repository

    repo = Gitlab::Git::Repository.new('gitlab/gitlab-ci')

    repo.path_to_repo
    # "/home/git/repositories/gitlab/gitlab-ci.git"

    repo.commit
    # #<Gitlab::Git::Commit:0x00000009e0fde0>

    repo.commit("23adsa43")
    # #<Gitlab::Git::Commit:0x00000004a0fda3>

    # Get 10 recent commits for `master` branch for `app` directory
    repo.commits("master", 'app/', 10)

    # Get 10..15 recent commits for `master` branch
    repo.commits("master", nil, 10, 5)

    # Get 30..40 recent commits until `23dae49a`
    repo.commits("23dae49a", nil, 10, 5)

    # Get branches and tags
    repo.branches
    repo.tags

    # Get branch or tag names
    repo.branch_names
    repo.tag_names

    # Archive repo to `/tmp` dir
    repo.archive_repo('master', '/tmp')

    # Bare repo size in MB.
    repo.size
    # 10.43
    
    # Commits between branches
    repo.commits_between('dev', 'master')
    # [ <Gitlab::Git::Commit:0x000..>, <Gitlab::Git::Commit:0x000..>]
    
    # Diff between branches
    repo.diffs_between('dev', 'master')
    # [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

    # Search for code
    repo.search_files('rspec', 'master')
    # [ <Gitlab::Git::BlobSnippet:0x000..>, <Gitlab::Git::BlobSnippet:0x000..>]
   
