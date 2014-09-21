require "spec_helper"

describe Gitlab::Git::Diff do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  before do
    @raw_diff_hash = {
      diff: <<EOT.gsub(/^ {8}/, "").sub(/\n$/, ""),
        --- a/.gitmodules
        +++ b/.gitmodules
        @@ -4,3 +4,6 @@
         [submodule "gitlab-shell"]
         	path = gitlab-shell
         	url = https://github.com/gitlabhq/gitlab-shell.git
        +[submodule "gitlab-grack"]
        +	path = gitlab-grack
        +	url = https://gitlab.com/gitlab-org/gitlab-grack.git
EOT
      new_path: '.gitmodules',
      old_path: '.gitmodules',
      a_mode: '100644',
      b_mode: '100644',
      new_file: false,
      renamed_file: false,
      deleted_file: false,
    }

    @rugged_diff = repository.rugged.diff("master^", "master", paths:
                                          [".gitmodules"]).patches.first
  end

  describe :new do
    context 'init from hash' do
      before do
        @diff = Gitlab::Git::Diff.new(@raw_diff_hash)
      end

      it { @diff.to_hash.should == @raw_diff_hash }
    end

    context 'init from rugged' do
      before do
        @diff = Gitlab::Git::Diff.new(@rugged_diff)
      end

      it { @diff.to_hash.should == @raw_diff_hash }
    end
  end

  describe :between do
    let(:diffs) { Gitlab::Git::Diff.between(repository, 'feature', 'master') }
    subject { diffs }

    it { should be_kind_of Array }
    its(:size) { should eq(1) }

    context :diff do
      subject { diffs.first }

      it { should be_kind_of Gitlab::Git::Diff }
      its(:new_path) { should == 'files/ruby/feature.rb' }
      its(:diff) { should include '+class Feature' }
    end
  end
end
