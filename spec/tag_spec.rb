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

    it { tag.name.should == "v1.2.1" }
    it { tag.target.should == "2ac1f24e253e08135507d0830508febaaccf02ee" }
    it { tag.message.should == "Version 1.2.1" }
  end

  it { repository.tags.size.should == SeedRepo::Repo::TAGS.size }
end
