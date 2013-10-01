require "spec_helper"

describe Gitlab::Git::Diff do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  before do
    @raw_diff_hash = {
      diff: 'Hello world',
      new_path: 'temp.rb',
      old_path: 'test.rb',
      a_mode: '100644',
      b_mode: '100644',
      new_file: false,
      renamed_file: true,
      deleted_file: false,
    }

    @grit_diff = double('Grit::Diff', @raw_diff_hash)
  end

  describe :new do
    context 'init from grit' do
      before do
        @diff = Gitlab::Git::Diff.new(@raw_diff_hash)
      end

      it { @diff.to_hash.should == @raw_diff_hash }
    end

    context 'init from hash' do
      before do
        @diff = Gitlab::Git::Diff.new(@grit_diff)
      end

      it { @diff.to_hash.should == @raw_diff_hash }
    end
  end

  describe :between do
    let(:diffs) { Gitlab::Git::Diff.between(repository, 'master', 'stable') }
    subject { diffs }

    it { should be_kind_of Array }
    its(:size) { should eq(73) }

    context :diff do
      subject { diffs.first }

      it { should be_kind_of Gitlab::Git::Diff }
      its(:new_path) { should == '.gitignore' }
      its(:diff) { should include 'Vagrantfile' }
    end
  end
end
