require "spec_helper"

describe Gitlab::Git::Repository do
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
    its(:last) { should == "v1.1.0" }
    it { should include("v1.0.0") }
    it { should_not include("v5.0.0") }
  end

  shared_examples 'archive check' do |extenstion|
    it { archive.should match(/tmp\/gitlab-git-test.git\/gitlab-git-test-5937ac0a/) }
    it { archive.should end_with extenstion }
    it { File.exists?(archive).should be_true }
    it { File.size?(archive).should_not be_nil }
  end

  describe :archive do
    let(:archive) { repository.archive_repo('master', '/tmp') }
    after { FileUtils.rm_r(archive) }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe :archive_zip do
    let(:archive) { repository.archive_repo('master', '/tmp', 'zip') }
    after { FileUtils.rm_r(archive) }

    it_should_behave_like 'archive check', '.zip'
  end

  describe :archive_bz2 do
    let(:archive) { repository.archive_repo('master', '/tmp', 'tbz2') }
    after { FileUtils.rm_r(archive) }

    it_should_behave_like 'archive check', '.tar.bz2'
  end

  describe :archive_fallback do
    let(:archive) { repository.archive_repo('master', '/tmp', 'madeup') }
    after { FileUtils.rm_r(archive) }

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

  describe :heads do
    let(:heads) { repository.heads }
    subject { heads }

    it { should be_kind_of Array }
    its(:size) { should eq(3) }

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
    its(:last) { should == 'v1.1.0' }
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
    let(:submodules) { repository.submodules(SeedRepo::Commit::ID) }

    it { submodules.should be_kind_of Hash }
    it { submodules.empty?.should be_false }

    describe :submodule do
      let(:submodule) { submodules.first }

      it 'should have valid data' do
        submodule.should == [
          "six", {
            "id"=>"409f37c4f05865e4fb208c771485f211a22c4c2d",
            "path"=>"six",
            "url"=>"git://github.com/randx/six.git"
          }
        ]
      end
    end
  end

  describe :commit_count do
    it { repository.commit_count("master").should == 13 }
    it { repository.commit_count("feature").should == 9 }
  end

  describe :archive_repo do
    it { repository.archive_repo('master', '/tmp').should == '/tmp/gitlab-git-test.git/gitlab-git-test-5937ac0a7beb003549fc5fd26fc247adbce4a52e.tar.gz' }
  end

  describe "#reset" do
    change_path = File.join(TEST_NORMAL_REPO_PATH, "CHANGELOG")
    untracked_path = File.join(TEST_NORMAL_REPO_PATH, "UNTRACKED")
    tracked_path = File.join(TEST_NORMAL_REPO_PATH, "files", "ruby", "popen.rb")

    change_text = "New changelog text"
    untracked_text = "This file is untracked"

    reset_commit = "d14d6c0abdd253381df51a723d58691b2ee1ab08"

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
        @normal_repo.reset("HEAD~3", :hard)
      end

      it "should replace the working directory with the content of the index" do
        File.open(change_path, "r") do |f|
          expect(f.each_line.first).not_to eq(change_text)
        end

        File.open(tracked_path, "r") do |f|
          expect(f.each_line.to_a[8]).to include('raise "System commands')
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

  describe "#remote_names" do
    let(:remotes) { repository.remote_names }

    it "should have one entry: 'origin'" do
      expect(remotes).to have(1).items
      expect(remotes.first).to eq("origin")
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
      @repo.remote_add("new_remote", SeedHelper::GITHUB_URL)
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
      repo.diff("master", "feature").each do |single_diff|
        expect(diff_text.include?(single_diff.diff)).to be_true
      end
    end

    it "should restrict its output to +paths+" do
      diff_text = repo.diff_text("master", "feature", "files")
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
    end

    after(:all) do
      # Erase our commits so other tests get the original repo
      repo = Gitlab::Git::Repository.new(TEST_REPO_PATH).rugged
      repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
    end
  end

  describe "branch_names_contains" do
    subject { repository.branch_names_contains(SeedRepo::LastCommit::ID) }

    it { should include('master') }
    it { should_not include('feature') }
    it { should_not include('fix') }
  end
end
