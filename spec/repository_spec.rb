require "spec_helper"

describe Gitlab::Git::Repository do
  include EncodingHelper

  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe "Respond to" do
    subject { repository }

    it { should respond_to(:raw) }
    it { should respond_to(:rugged) }
    it { should respond_to(:root_ref) }
    it { should respond_to(:tags) }
  end

  describe "#discover_default_branch" do
    let(:master) { 'master' }
    let(:feature) { 'feature' }
    let(:feature2) { 'feature2' }

    it "returns 'master' when master exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([feature, master])
      repository.discover_default_branch.should == 'master'
    end

    it "returns non-master when master exists but default branch is set to something else" do
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/feature')
      repository.should_receive(:branch_names).at_least(:once).and_return([feature, master])
      repository.discover_default_branch.should == 'feature'
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/master')
    end

    it "returns a non-master branch when only one exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([feature])
      repository.discover_default_branch.should == 'feature'
    end

    it "returns a non-master branch when more than one exists and master does not" do
      repository.should_receive(:branch_names).at_least(:once).and_return([feature, feature2])
      repository.discover_default_branch.should == 'feature'
    end

    it "returns nil when no branch exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([])
      repository.discover_default_branch.should be_nil
    end
  end

  describe :branch_names do
    subject { repository.branch_names }

    it { should have(SeedRepo::Repo::BRANCHES.size).elements }
    it { should include("master") }
    it { should_not include("branch-from-space") }
  end

  describe :tag_names do
    subject { repository.tag_names }

    it { should be_kind_of Array }
    it { should have(SeedRepo::Repo::TAGS.size).elements }
    its(:last) { should == "v1.2.1" }
    it { should include("v1.0.0") }
    it { should_not include("v5.0.0") }
  end

  shared_examples 'archive check' do |extenstion|
    it { metadata['ArchivePath'].should match(/tmp\/gitlab-git-test.git\/gitlab-git-test-master-#{SeedRepo::LastCommit::ID}/) }
    it { metadata['ArchivePath'].should end_with extenstion }
  end

  describe :archive do
    let(:metadata) { repository.archive_metadata('master', '/tmp') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe :archive_zip do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'zip') }

    it_should_behave_like 'archive check', '.zip'
  end

  describe :archive_bz2 do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'tbz2') }

    it_should_behave_like 'archive check', '.tar.bz2'
  end

  describe :archive_fallback do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'madeup') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe :size do
    subject { repository.size }

    it { should < 2 }
  end

  describe :has_commits? do
    it { repository.has_commits?.should be_true }
  end

  describe :empty? do
    it { repository.empty?.should be_false }
  end

  describe :bare? do
    it { repository.bare?.should be_true }
  end

  describe :heads do
    let(:heads) { repository.heads }
    subject { heads }

    it { should be_kind_of Array }
    its(:size) { should eq(SeedRepo::Repo::BRANCHES.size) }

    context :head do
      subject { heads.first }

      its(:name) { should == "feature" }

      context :commit do
        subject { heads.first.target }

        it { should == "0b4bc9a49b562e85de7cc9e834518ea6828729b9" }
      end
    end
  end

  describe :ref_names do
    let(:ref_names) { repository.ref_names }
    subject { ref_names }

    it { should be_kind_of Array }
    its(:first) { should == 'feature' }
    its(:last) { should == 'v1.2.1' }
  end

  describe :search_files do
    let(:results) { repository.search_files('rails', 'master') }
    subject { results }

    it { should be_kind_of Array }
    its(:first) { should be_kind_of Gitlab::Git::BlobSnippet }

    context 'blob result' do
      subject { results.first }

      its(:ref) { should == 'master' }
      its(:filename) { should == 'CHANGELOG' }
      its(:startline) { should == 35 }
      its(:data) { should include "Ability to filter by multiple labels" }
    end
  end

  context :submodules do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

    context 'where repo has submodules' do
      let(:submodules) { repository.submodules('master') }
      let(:submodule) { submodules.first }

      it { submodules.should be_kind_of Hash }
      it { submodules.empty?.should be_false }

      it 'should have valid data' do
        submodule.should == [
          "six", {
            "id"=>"409f37c4f05865e4fb208c771485f211a22c4c2d",
            "path"=>"six",
            "url"=>"git://github.com/randx/six.git"
          }
        ]
      end

      it 'should handle nested submodules correctly' do
        nested = submodules['nested/six']
        expect(nested['path']).to eq('nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should handle deeply nested submodules correctly' do
        nested = submodules['deeper/nested/six']
        expect(nested['path']).to eq('deeper/nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should not have an entry for an invalid submodule' do
        expect(submodules).not_to have_key('invalid/path')
      end

      it 'should not have an entry for an uncommited submodule dir' do
        submodules = repository.submodules('fix-existing-submodule-dir')
        expect(submodules).not_to have_key('submodule-existing-dir')
      end

      it 'should handle tags correctly' do
        submodules = repository.submodules('v1.2.1')
        submodule.should == [
          "six", {
            "id"=>"409f37c4f05865e4fb208c771485f211a22c4c2d",
            "path"=>"six",
            "url"=>"git://github.com/randx/six.git"
          }
        ]
      end
    end

    context 'where repo doesn\'t have submodules' do
      let(:submodules) { repository.submodules('6d39438') }
      it 'should return an empty hash' do
        expect(submodules).to be_empty
      end
    end
  end

  describe :commit_count do
    it { repository.commit_count("master").should == 23 }
    it { repository.commit_count("feature").should == 9 }
  end

  describe "#reset" do
    change_path = File.join(TEST_NORMAL_REPO_PATH, "CHANGELOG")
    untracked_path = File.join(TEST_NORMAL_REPO_PATH, "UNTRACKED")
    tracked_path = File.join(TEST_NORMAL_REPO_PATH, "files", "ruby", "popen.rb")

    change_text = "New changelog text"
    untracked_text = "This file is untracked"

    reset_commit = SeedRepo::LastCommit::ID

    context "--hard" do
      before(:all) do
        # Modify a tracked file
        File.open(change_path, "w") do |f|
          f.write(change_text)
        end

        # Add an untracked file to the working directory
        File.open(untracked_path, "w") do |f|
          f.write(untracked_text)
        end

        @normal_repo = Gitlab::Git::Repository.new(TEST_NORMAL_REPO_PATH)
        @normal_repo.reset("HEAD", :hard)
      end

      it "should replace the working directory with the content of the index" do
        File.open(change_path, "r") do |f|
          expect(f.each_line.first).not_to eq(change_text)
        end

        File.open(tracked_path, "r") do |f|
          expect(f.each_line.to_a[8]).to include('raise RuntimeError, "System commands')
        end
      end

      it "should not touch untracked files" do
        expect(File.exist?(untracked_path)).to be_true
      end

      it "should move the HEAD to the correct commit" do
        new_head = @normal_repo.rugged.head.target.oid
        expect(new_head).to eq(reset_commit)
      end

      it "should move the tip of the master branch to the correct commit" do
        new_tip = @normal_repo.rugged.references["refs/heads/master"].
          target.oid

        expect(new_tip).to eq(reset_commit)
      end

      after(:all) do
        # Fast-forward to the original HEAD
        FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
        ensure_seeds
      end
    end
  end

  describe "#checkout" do
    new_branch = "foo_branch"

    context "-b" do
      before(:all) do
        @normal_repo = Gitlab::Git::Repository.new(TEST_NORMAL_REPO_PATH)
        @normal_repo.checkout(new_branch, { b: true }, "origin/feature")
      end

      it "should create a new branch" do
        expect(@normal_repo.rugged.branches[new_branch]).to_not be_nil
      end

      it "should move the HEAD to the correct commit" do
        expect(@normal_repo.rugged.head.target.oid).to(
          eq(@normal_repo.rugged.branches["origin/feature"].target.oid)
        )
      end

      it "should refresh the repo's #heads collection" do
        head_names = @normal_repo.heads.map { |h| h.name }
        expect(head_names).to include(new_branch)
      end

      after(:all) do
        FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
        ensure_seeds
      end
    end

    context "without -b" do
      context "and specifying a nonexistent branch" do
        it "should not do anything" do
          normal_repo = Gitlab::Git::Repository.new(TEST_NORMAL_REPO_PATH)

          expect { normal_repo.checkout(new_branch) }.to raise_error
          expect(normal_repo.rugged.branches[new_branch]).to be_nil
          expect(normal_repo.rugged.head.target.oid).to(
            eq(normal_repo.rugged.branches["master"].target.oid)
          )

          head_names = normal_repo.heads.map { |h| h.name }
          expect(head_names).not_to include(new_branch)
        end

        after(:all) do
          FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
          ensure_seeds
        end
      end

      context "and with a valid branch" do
        before(:all) do
          @normal_repo = Gitlab::Git::Repository.new(TEST_NORMAL_REPO_PATH)
          @normal_repo.rugged.branches.create("feature", "origin/feature")
          @normal_repo.checkout("feature")
        end

        it "should move the HEAD to the correct commit" do
          expect(@normal_repo.rugged.head.target.oid).to(
            eq(@normal_repo.rugged.branches["feature"].target.oid)
          )
        end

        it "should update the working directory" do
          File.open(File.join(TEST_NORMAL_REPO_PATH, ".gitignore"), "r") do |f|
            expect(f.read.each_line.to_a).not_to include(".DS_Store\n")
          end
        end

        after(:all) do
          FileUtils.rm_rf(TEST_NORMAL_REPO_PATH)
          ensure_seeds
        end
      end
    end
  end

  describe "#delete_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.delete_branch("feature")
    end

    it "should remove the branch from the repo" do
      expect(@repo.rugged.branches["feature"]).to be_nil
    end

    it "should update the repo's #heads collection" do
      expect(@repo.heads).not_to include("feature")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end


  describe "#create_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
    end

    it "should create a new branch" do
      expect(@repo.create_branch('new_branch', 'master')).not_to be_nil
    end

    it "should create a new branch with the right name" do
      expect(@repo.create_branch('another_branch', 'master').name).to eq('another_branch')
    end

    it "should fail if we create an existing branch" do
      @repo.create_branch('duplicated_branch', 'master')
      expect{@repo.create_branch('duplicated_branch', 'master')}.to raise_error("Branch duplicated_branch already exists")
    end

    it "should fail if we create a branch from a non existing ref" do
      expect{@repo.create_branch('branch_based_in_wrong_ref', 'master_2_the_revenge')}.to raise_error("Invalid reference master_2_the_revenge")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#add_tag" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
    end

    let(:add_tag_options) do
      {
        tagger: {
          email: 'user@example.com',
          name: 'Test User',
          time: Time.now
        },
        message: "", # Rugged does not support passing only a tagger without a message
      }
    end

    it "adds a tag to the repo" do
      tag = @repo.add_tag("my_pretty_tag", "master", add_tag_options.merge({
        message: "this is a new tag" }))
      expect(tag).not_to be_nil
      expect(tag.name).to eq("my_pretty_tag")
      expect(tag.target).to eq("master")
      expect(tag.message).to eq("this is a new tag")
    end

    it "adds a lightweight tag to the repo" do
      tag = @repo.add_tag("my_lightweight_tag", "master")
      expect(tag).not_to be_nil
      expect(tag.name).to eq("my_lightweight_tag")
      expect(tag.target).to eq("master")
      expect(tag.message).to be_nil
    end

    it "adds a tag without a message" do
      tag = @repo.add_tag("my_messageless_tag", "master", add_tag_options)
      expect(tag.message).to be_empty
    end

    it "fails to add the same tag twice" do
      @repo.add_tag("my_duplicated_tag", "master", add_tag_options)
      expect{ @repo.add_tag("my_duplicated_tag", "master", add_tag_options) }.
        to raise_error("Tag my_duplicated_tag already exists")
    end

    it "fails to add a tag with an invalid target reference" do
      expect{ @repo.add_tag("invalid_tag", "invalid_target", add_tag_options) }.
        to raise_error("Target invalid_target is invalid")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_names" do
    let(:remotes) { repository.remote_names }

    it "should have one entry: 'origin'" do
      expect(remotes).to have(1).items
      expect(remotes.first).to eq("origin")
    end
  end

  describe "#refs_hash" do
    let(:refs) { repository.refs_hash }

    it "should have as many entries as branches and tags" do
      expected_refs = SeedRepo::Repo::BRANCHES + SeedRepo::Repo::TAGS
      expect(refs).to have(expected_refs.size).items
    end
  end

  describe "#remote_delete" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.remote_delete("expendable")
    end

    it "should remove the remote" do
      expect(@repo.rugged.remotes).not_to include("expendable")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_add" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.remote_add("new_remote", SeedHelper::GITLAB_URL)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes.each_name.to_a).to include("new_remote")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_update" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.remote_update("expendable", url: TEST_NORMAL_REPO_PATH)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes["expendable"].url).to(
        eq(TEST_NORMAL_REPO_PATH)
      )
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#diff_text" do
    let(:repo) { Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH) }

    it "should contain the same diffs as #diff" do
      diff_text = repo.diff_text("master", "feature")
      diff_text = encode_utf8(diff_text)
      repo.diff("master", "feature").each do |single_diff|
        expect(diff_text.include?(single_diff.diff)).to be_true
      end
    end

    it "should restrict its output to +paths+" do
      diff_text = repo.diff_text("master", "feature", nil, "files")
      repo.rugged.diff("master", "feature").each_delta do |delta|
        path = delta.old_file[:path]
        match_text = "diff --git a/#{path}"

        if path.match(/^files/)
          expect(diff_text).to include(match_text)
        else
          expect(diff_text).not_to include(match_text)
        end
      end
    end
  end

  describe "#log" do
    commit_with_old_name = nil
    commit_with_new_name = nil
    rename_commit = nil

    before(:all) do
      # Add new commits so that there's a renamed file in the commit history
      repo = Gitlab::Git::Repository.new(TEST_REPO_PATH).rugged

      commit_with_old_name = new_commit_edit_old_file(repo)
      rename_commit = new_commit_move_file(repo)
      commit_with_new_name = new_commit_edit_new_file(repo)
    end

    context "where 'follow' == true" do
      options = { ref: "master", follow: true }

      context "and 'path' is a directory" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the new filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding/CHANGELOG"))
        end

        it "should follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the old filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_old_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_new_name)
        end
      end

      context "unknown ref" do
        let(:log_commits) { repository.log(options.merge(ref: 'unknown')) }

        it "should return empty" do
          expect(log_commits).to eq([])
        end
      end
    end

    context "where 'follow' == false" do
      options = { follow: false }

      context "and 'path' is a directory" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the new filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding/CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the old filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_old_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_new_name)
        end
      end

      context "and 'path' includes a directory that used to be a file" do
        let(:log_commits) do
          repository.log(options.merge(ref: "refs/heads/fix-blob-path", path: "files/testdir/file.txt"))
        end

        it "should return a list of commits" do
          expect(log_commits.size).to eq(1)
        end
      end
    end

    after(:all) do
      # Erase our commits so other tests get the original repo
      repo = Gitlab::Git::Repository.new(TEST_REPO_PATH).rugged
      repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end
  end

  describe "#commits_between" do
    context 'two SHAs' do
      let(:first_sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:second_sha) { '0e50ec4d3c7ce42ab74dda1d422cb2cbffe1e326' }

      it 'returns the number of commits between' do
        expect(repository.commits_between(first_sha, second_sha).count).to eq(3)
      end
    end

    context 'SHA and master branch' do
      let(:sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:branch) { 'master' }

      it 'returns the number of commits between a sha and a branch' do
        expect(repository.commits_between(sha, branch).count).to eq(3)
      end

      it 'returns the number of commits between a branch and a sha' do
        expect(repository.commits_between(branch, sha).count).to eq(0) # sha is before branch
      end
    end

    context 'two branches' do
      let(:first_branch) { 'feature' }
      let(:second_branch) { 'master' }

      it 'returns the number of commits between' do
        expect(repository.commits_between(first_branch, second_branch).count).to eq(15)
      end
    end
  end

  describe "branch_names_contains" do
    subject { repository.branch_names_contains(SeedRepo::LastCommit::ID) }

    it { should include('master') }
    it { should_not include('feature') }
    it { should_not include('fix') }
  end

  describe '#autocrlf' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.rugged.config['core.autocrlf'] = true
    end

    it 'return the value of the autocrlf option' do
      expect(@repo.autocrlf).to be(true)
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#autocrlf=' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new(TEST_MUTABLE_REPO_PATH)
      @repo.rugged.config['core.autocrlf'] = false
    end

    it 'should set the autocrlf option to the provided option' do
      @repo.autocrlf = :input

      File.open(File.join(TEST_MUTABLE_REPO_PATH, '.git', 'config')) do |config_file|
        expect(config_file.read).to match('autocrlf = input')
      end
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#branches with deleted branch' do
    before(:each) do
      ref = double()
      ref.stub(:name) { 'bad-branch' }
      ref.stub(:target) { raise Rugged::ReferenceError }
      repository.rugged.stub(:branches) { [ref] }
    end

    it 'should return empty branches' do
      expect(repository.branches).to eq([])
    end
  end

  describe '#branch_count' do
    before(:each) do
      valid_ref   = double(:ref)
      invalid_ref = double(:ref)

      valid_ref.stub(name: 'master', target: double(:target))

      invalid_ref.stub(name: 'bad-branch')
      invalid_ref.stub(:target) { raise Rugged::ReferenceError }

      repository.rugged.stub(branches: [valid_ref, invalid_ref])
    end

    it 'returns the number of branches' do
      expect(repository.branch_count).to eq(1)
    end
  end

  describe '#mkdir' do
    let(:commit_options) do
      {
        author: {
          email: 'user@example.com',
          name: 'Test User',
          time: Time.now
        },
        committer: {
          email: 'user@example.com',
          name: 'Test User',
          time: Time.now
        },
        commit: {
          message: 'Test message',
          branch: 'refs/heads/fix',
        }
      }
    end

    def generate_diff_for_path(path)
      "diff --git a/#{path}/.gitkeep b/#{path}/.gitkeep
new file mode 100644
index 0000000..e69de29
--- /dev/null
+++ b/#{path}/.gitkeep\n"
    end

    shared_examples 'mkdir diff check' do |path, expected_path|
      it 'creates a directory' do
        result = repository.mkdir(path, commit_options)
        expect(result).not_to eq(nil)

        diff_text = repository.diff_text("#{result}~1", result)
        expected = generate_diff_for_path(expected_path)
        expect(diff_text).to eq(expected)

        # Verify another mkdir doesn't create a directory that already exists
        expect{ repository.mkdir(path, commit_options) }.to raise_error('Directory already exists')
      end
    end

    describe 'creates a directory in root directory' do
      it_should_behave_like 'mkdir diff check', 'new_dir', 'new_dir'
    end

    describe 'creates a directory in subdirectory' do
      it_should_behave_like 'mkdir diff check', 'files/ruby/test', 'files/ruby/test'
    end

    describe 'creates a directory in subdirectory with a slash' do
      it_should_behave_like 'mkdir diff check', '/files/ruby/test2', 'files/ruby/test2'
    end

    describe 'creates a directory in subdirectory with multiple slashes' do
      it_should_behave_like 'mkdir diff check', '//files/ruby/test3', 'files/ruby/test3'
    end

    describe 'handles relative paths' do
      it_should_behave_like 'mkdir diff check', 'files/ruby/../test_relative', 'files/test_relative'
    end

    describe 'creates nested directories' do
      it_should_behave_like 'mkdir diff check', 'files/missing/test', 'files/missing/test'
    end

    it 'does not attempt to create a directory with invalid relative path' do
      expect{ repository.mkdir('../files/missing/test', commit_options) }.to raise_error('Invalid path')
    end

    it 'does not attempt to overwrite a file' do
      expect{ repository.mkdir('README.md', commit_options) }.to raise_error('Directory already exists as a file')
    end

    it 'does not attempt to overwrite a directory' do
      expect{ repository.mkdir('files', commit_options) }.to raise_error('Directory already exists')
    end
  end

  describe "#ls_files" do
    let(:master_file_paths) { repository.ls_files("master") }
    let(:not_existed_branch) { repository.ls_files("not_existed_branch") }

    it "read every file paths of master branch" do
      expect(master_file_paths.length).to equal(39)
    end

    it "reads full file paths of master branch" do
      expect(master_file_paths).to include("files/html/500.html")
    end

    it "dose not read submodule directory and empty directory of master branch" do
      expect(master_file_paths).not_to include("six")
    end

    it "does not include 'nil'" do
      expect(master_file_paths).not_to include(nil)
    end

    it "returns empty array when not existed branch" do
      expect(not_existed_branch.length).to equal(0)
    end
  end
end
