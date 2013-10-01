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
    let(:stable) { 'stable' }

    it "returns 'master' when master exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      repository.discover_default_branch.should == 'master'
    end

    it "returns non-master when master exists but default branch is set to something else" do
      File.write(File.join(repository.path, '.git', 'HEAD'), 'ref: refs/heads/stable')
      repository.should_receive(:branch_names).at_least(:once).and_return([stable, master])
      repository.discover_default_branch.should == 'stable'
      File.write(File.join(repository.path, '.git', 'HEAD'), 'ref: refs/heads/master')
    end

    it "returns a non-master branch when only one exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([stable])
      repository.discover_default_branch.should == 'stable'
    end

    it "returns nil when no branch exists" do
      repository.should_receive(:branch_names).at_least(:once).and_return([])
      repository.discover_default_branch.should be_nil
    end
  end

  describe :branch_names do
    subject { repository.branch_names }

    it { should have(32).elements }
    it { should include("master") }
    it { should_not include("branch-from-space") }
  end

  describe :tag_names do
    subject { repository.tag_names }

    it { should be_kind_of Array }
    it { should have(16).elements }
    its(:first) { should == "v2.2.0pre" }
    it { should include("v1.2.0") }
    it { should_not include("v5.0.0") }
  end

  describe :archive do
    let(:archive) { repository.archive_repo('master', '/tmp') }
    after { FileUtils.rm_r(archive) }

    it { archive.should match(/tmp\/gitlabhq.git\/gitlabhq-bcf03b5/) }
    it { File.exists?(archive).should be_true }
  end

  describe :size do
    subject { repository.size }

    it { should == 43.19 }
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
    its(:size) { should eq(32) }

    context :head do
      subject { heads.first }

      its(:name) { should == '2_3_notes_fix' }

      context :commit do
        subject { heads.first.commit }

        its(:id) { should == '8470d70da67355c9c009e4401746b1d5410af2e3' }
      end
    end
  end

  describe :ref_names do
    let(:ref_names) { repository.ref_names }
    subject { ref_names }

    it { should be_kind_of Array }
    its(:first) { should == '2_3_notes_fix' }
    its(:last) { should == 'v0.9.4' }
  end

  describe :search_files do
    let(:results) { repository.search_files('rails', 'master') }
    subject { results }

    it { should be_kind_of Array }
    its(:first) { should be_kind_of Gitlab::Git::BlobSnippet }

    context 'blob result' do
      subject { results.first }

      its(:ref) { should == 'master' }
      its(:filename) { should == '.travis.yml' }
      its(:startline) { should == 6 }
      its(:data) { should include "bundle exec rake db:seed_fu RAILS_ENV=test" }
    end
  end
end
