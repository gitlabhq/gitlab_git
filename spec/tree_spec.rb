require "spec_helper"

describe Gitlab::Git::Tree do
  let(:repository) { Gitlab::Git::Repository.new('gitlabhq', 'master') }
  let(:tree) { Gitlab::Git::Tree.new(repository, ValidCommit::ID) }

  it { tree.exists?.should be_true }
  it { tree.empty?.should be_false }
  it { tree.up_dir?.should be_false }
  it { tree.is_blob?.should be_false }
  it { tree.readme.should be_kind_of Grit::Blob }

  describe :trees do
    it { tree.trees.size.should == 10 }
    it { tree.trees.first.should be_kind_of Grit::Tree }
    it { tree.trees.first.id.should == 'ba18d73c8fa3a326a5779b75bda0384dfb360240' }
  end

  describe :blobs do
    it { tree.blobs.size.should == 16 }
    it { tree.blobs.first.should be_kind_of Grit::Blob }
    it { tree.blobs.first.id.should == '87c3f5a1c158686373e3179b503b0a7b7987587b' }
  end

  describe :submodules do
    it { tree.submodules.size.should == 0 }
  end
end
