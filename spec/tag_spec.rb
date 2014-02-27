require "spec_helper"

describe Gitlab::Git::Tag do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe 'first tag' do
    let(:tag) { repository.tags.first }

    it { tag.name.should == "v1.0.0" }
    it { tag.target.should == "f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8" }
  end

  describe 'last tag' do
    let(:tag) { repository.tags.last }

    it { tag.name.should == "v1.1.0" }
    it { tag.target.should == "8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b" }
  end

  it { repository.tags.size.should == 2 }
end
