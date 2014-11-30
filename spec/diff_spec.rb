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
         \tpath = gitlab-shell
         \turl = https://github.com/gitlabhq/gitlab-shell.git
        +[submodule "gitlab-grack"]
        +	path = gitlab-grack
        +	url = https://gitlab.com/gitlab-org/gitlab-grack.git
EOT
      new_path: ".gitmodules",
      old_path: ".gitmodules",
      a_mode: '100644',
      b_mode: '100644',
      new_file: false,
      renamed_file: false,
      deleted_file: false,
    }

    @rugged_diff = repository.rugged.diff("5937ac0a7beb003549fc5fd26fc247adbce4a52e^", "5937ac0a7beb003549fc5fd26fc247adbce4a52e", paths:
                                          [".gitmodules"]).patches.first
  end

  describe :new do
    context "init from hash" do
      before do
        @diff = Gitlab::Git::Diff.new(@raw_diff_hash)
      end

      it { @diff.to_hash == @raw_diff_hash }
    end

    context "init from rugged" do
      before do
        @diff = Gitlab::Git::Diff.new(@rugged_diff)
      end

      it { @diff.to_hash == @raw_diff_hash }
    end
  end

  describe :between do
    let(:diffs) { Gitlab::Git::Diff.between(repository, 'feature', 'master') }
    subject { diffs }

    it { should be_kind_of Array }
    it { diffs.size == 1 }

    context :diff do
      subject { diffs.first }

      it { should be_kind_of Gitlab::Git::Diff }
      it { subject.new_path == 'files/ruby/feature.rb' }
      it { expect(subject.diff).to include '+class Feature' }
    end
  end

  describe :submodule? do
    before do
      commit = repository.lookup('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      @diffs = commit.parents[0].diff(commit).patches
    end

    it { Gitlab::Git::Diff.new(@diffs[0]).submodule? == false }
    it { Gitlab::Git::Diff.new(@diffs[1]).submodule? == true }
  end
end
