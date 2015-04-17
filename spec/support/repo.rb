module SeedRepo
  module Repo
    HEAD = "master"
    BRANCHES = ["feature", "fix", "fix-existing-submodule-dir", "master"]
    TAGS = ["v1.0.0", 'v1.1.0', 'v1.2.0', 'v1.2.1']
  end
end

# Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
# contents of CHANGELOG with a single new line of text.
def new_commit_edit_old_file(repo)
  oid = repo.write("I replaced the changelog with this text", :blob)
  index = repo.index
  index.read_tree(repo.head.target.tree)
  index.add(path: "CHANGELOG", oid: oid, mode: 0100644)

  options = commit_options(
    repo,
    index,
    "Edit CHANGELOG in its original location"
  )

  sha = Rugged::Commit.create(repo, options)
  repo.lookup(sha)
end

# Writes a new commit to the repo and returns a Rugged::Commit.  Moves the
# CHANGELOG file to the encoding/ directory.
def new_commit_move_file(repo)
  blob_oid = repo.head.target.tree.detect { |i| i[:name] == "CHANGELOG" }[:oid]
  file_content = repo.lookup(blob_oid).content
  oid = repo.write(file_content, :blob)
  index = repo.index
  index.read_tree(repo.head.target.tree)
  index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)
  index.remove("CHANGELOG")

  options = commit_options(repo, index, "Move CHANGELOG to encoding/")

  sha = Rugged::Commit.create(repo, options)
  repo.lookup(sha)
end

# Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
# contents of encoding/CHANGELOG with new text.
def new_commit_edit_new_file(repo)
  oid = repo.write("I'm a new changelog with different text", :blob)
  index = repo.index
  index.read_tree(repo.head.target.tree)
  index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)

  options = commit_options(repo, index, "Edit encoding/CHANGELOG")

  sha = Rugged::Commit.create(repo, options)
  repo.lookup(sha)
end

# Build the options hash that's passed to Rugged::Commit#create
def commit_options(repo, index, message)
  options = {}
  options[:tree] = index.write_tree(repo)
  options[:author] = {
    email: "test@example.com",
    name: "Test Author",
    time: Time.gm(2014, "mar", 3, 20, 15, 1)
  }
  options[:committer] = {
    email: "test@example.com",
    name: "Test Author",
    time: Time.gm(2014, "mar", 3, 20, 15, 1)
  }
  options[:message] ||= message
  options[:parents] = repo.empty? ? [] : [repo.head.target].compact
  options[:update_ref] = "HEAD"

  options
end
