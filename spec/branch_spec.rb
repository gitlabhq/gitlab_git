require "spec_helper"

describe Gitlab::Git::Branch do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe 'first branch' do
    let(:branch) { repository.branches.first }

    it { branch.name.should == "2_3_notes_fix" }
    it { branch.target.should == "8470d70da67355c9c009e4401746b1d5410af2e3" }
  end

  describe 'last branch' do
    let(:branch) { repository.branches.last }

    it { branch.name.should == "wiki" }
    it { branch.target.should == "621bfdb4aa6c5ef2b031f7c4fb7753eb80d7a5b5" }
  end

  it { repository.branches.size.should == 32 }
end
