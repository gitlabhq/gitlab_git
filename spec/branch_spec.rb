require "spec_helper"

describe Gitlab::Git::Branch do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  subject { repository.branches }

  it { should be_kind_of Array }
  its(:size) { should eq(SeedRepo::Repo::BRANCHES.size) }

  describe 'first branch' do
    let(:branch) { repository.branches.first }

    it { branch.name.should == SeedRepo::Repo::BRANCHES.first }
    it { branch.target.should == "0b4bc9a49b562e85de7cc9e834518ea6828729b9" }
  end

  describe 'last branch' do
    let(:branch) { repository.branches.last }

    it { branch.name.should == SeedRepo::Repo::BRANCHES.last }
    it { branch.target.should == SeedRepo::LastCommit::ID }
  end

  it { repository.branches.size.should == SeedRepo::Repo::BRANCHES.size }
end
