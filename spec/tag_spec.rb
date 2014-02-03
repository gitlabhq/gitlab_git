require "spec_helper"

describe Gitlab::Git::Tag do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe 'first tag' do
    let(:tag) { repository.tags.first }

    it { tag.name.should == "v0.9.4" }
    it { tag.target.should == "38d99e9a05aeec3de09c4a7af2d8af8b34ed5084" }
  end

  describe 'last tag' do
    let(:tag) { repository.tags.last }

    it { tag.name.should == "v2.2.0pre" }
    it { tag.target.should == "985804a92fe780a4729e9fdbf92e19496c0af15a" }
  end

  it { repository.tags.size.should == 16 }
end
