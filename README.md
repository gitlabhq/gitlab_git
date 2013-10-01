### GitLab Git

GitLab wrapper around git objects. Use patched Grit as main library for parsing git objects

#### Code status

* [![Build Status](https://travis-ci.org/gitlabhq/gitlab_git.png?branch=master)](https://travis-ci.org/gitlabhq/gitlab_git)
* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab_git.png)](https://codeclimate.com/github/gitlabhq/gitlab_git)
* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlab_git/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlab_git)


### How to use: 

#### Repository

    # Init repo with relative path according to repos_path. 
    # 
    repo = Gitlab::Git::Repository.new('/home/git/repositories/gitlab/gitlab-ci.git')

    repo.path
    # "/home/git/repositories/gitlab/gitlab-ci.git"

    repo.name
    # "gitlab-ci.git"

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
    
    # Search for code
    repo.search_files('rspec', 'master')
    # [ <Gitlab::Git::BlobSnippet:0x000..>, <Gitlab::Git::BlobSnippet:0x000..>]
 
    # Access to grit repo object 
    repo.grit

#### Tree

    # Tree object for root dir
    tree = Gitlab::Git::Tree.new(repo, '893ade32')

    # Tree object for sub dir
    tree = Gitlab::Git::Tree.new(repo, '893ade32', 'master', 'app/models/')

    # Get readme for this directory if exists
    tree.readme

    # Get directories  
    tree.trees
    # [ <Gitlab::Git::Tree:0x000>, ...]

    # Get blobs  
    tree.blobs
    # [ <Gitlab::Git::Blob:0x000>, ...]

    # Get submodules
    tree.submodules
    # [ <Grit::Submodule:0x000>, ...]

    # Check if subdir   
    tree.up_dir?

#### Blob

    # Blob object for Commit sha 893ade32
    blob = Gitlab::Git::Blob.find(repo, '893ade32', 'Gemfile')

    # Attributes 
    blob.id
    blob.name
    blob.size
    blob.data
    blob.mode
    blob.path
    blob.commit_id

#### Commit

##### Picking

     # Get commits collection with pagination
     Gitlab::Git::Commit.where(
       repo: repo,
       ref: 'master',
       path: 'app/models',
       limit: 10,
       offset: 5,
     )

     # Find single commit
     Gitlab::Git::Commit.find(repo, '29eda46b')
     Gitlab::Git::Commit.find(repo, 'v2.4.6')

     # Get last commit for HEAD
     commit = Gitlab::Git::Commit.last(repo)
     
     # Get last commit for specified file/directory
     Gitlab::Git::Commit.find_for_path(repo, '29eda46b', 'app/models')
    
     # Commits between branches
     Gitlab::Git::Commit.between(repo, 'dev', 'master')
     # [ <Gitlab::Git::Commit:0x000..>, <Gitlab::Git::Commit:0x000..>]
    

##### Commit object

     # Commit id
     commit.id
     commit.sha
     # ba8812a2de5e5ea191da6930a8ee1965873286e3

     commit.short_id
     # ba8812a2de

     commit.message
     commit.safe_message
     # Fix bug 891

     commit.parent_id
     # ba8812a2de5e5ea191da6930a8ee1965873286e3

     commit.diffs
     # [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]
     
     commit.created_at 
     commit.authored_date
     commit.committed_date
     # 2013-07-03 22:11:26 +0300

     commit.committer_name
     commit.author_name
     # John Smith
     
     commit.committer_email
     commit.author_email
     # jsmith@sample.com


#### Diff object

     # From commit
     commit.diffs
     # [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

     # Diff between several commits
     Gitlab::Git::Diff.between(repo, 'dev', 'master')
     # [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

#### Git blame

     # Git blame for file
     blame = Gitlab::Git::Blame.new(repo, 'master, 'app/models/project.rb')
     blame.each do |commit, lines|
       commit # <Gitlab::Git::Commit:0x000..>
       lines # ['class Project', 'def initialize']
     end
