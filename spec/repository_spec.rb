require "spec_helper"

describe Gitlab::Git::Repository do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe "Respond to" do
    subject { repository }

    it { should respond_to(:raw) }
    it { should respond_to(:grit) }
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
    it { archive.should match(/tmp\/testme.git\/testme-5937ac0a/) }
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

  describe :branches do
    let(:branches) { repository.branches }
    subject { branches }

    it { should be_kind_of Array }
    its(:size) { should eq(32) }

    context :branch do
      subject { branches.first }

      its(:name) { should == '2_3_notes_fix' }
      its(:target) { should == '8470d70da67355c9c009e4401746b1d5410af2e3' }
    end
  end

  describe :heads do
    let(:heads) { repository.heads }
    subject { heads }

    it { should be_kind_of Array }
    its(:size) { should eq(3) }

    context :head do
      subject { heads.first }

      its(:name) { should == 'feature' }

      context :commit do
        subject { heads.first.commit }

        its(:id) { should == '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }
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
end
