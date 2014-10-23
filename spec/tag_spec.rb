require "spec_helper"

describe Gitlab::Git::Tag do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe 'first tag' do
    let(:tag) { repository.tags.first }

    it { tag.name.should == "v1.0.0" }
    it { tag.target.should == "f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8" }
    it { tag.message.should == "Release" }
  end

  describe 'last tag' do
    let(:tag) { repository.tags.last }

    it { tag.name.should == "v1.2.0" }
    it { tag.target.should == "10d64eed7760f2811ee2d64b44f1f7d3b364f17b" }
    it { tag.message.should == "Version 1.2.0" }
  end

  it { repository.tags.size.should == 3 }
end
