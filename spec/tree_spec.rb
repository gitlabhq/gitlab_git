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
end
