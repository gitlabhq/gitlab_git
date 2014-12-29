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

      it { @diff.to_hash.should == @raw_diff_hash }
    end

    context "init from rugged" do
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

  describe :filter_diff_options do
    let(:options) { { max_size: 100, invalid_opt: true } }

    context "without default options" do
      let(:filtered_options) { Gitlab::Git::Diff.filter_diff_options(options) }

      it "should filter invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
      end
    end

    context "with default options" do
      let(:filtered_options) do
        default_options = { max_size: 5, bad_opt: 1, ignore_whitespace: true }
        Gitlab::Git::Diff.filter_diff_options(options, default_options)
      end

      it "should filter invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
        expect(filtered_options).not_to have_key(:bad_opt)
      end

      it "should merge with default options" do
        expect(filtered_options).to have_key(:ignore_whitespace)
      end

      it "should override default options" do
        expect(filtered_options).to have_key(:max_size)
        expect(filtered_options[:max_size]).to eq(100)
      end
    end
  end

  describe :submodule? do
    before do
      commit = repository.lookup('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      @diffs = commit.parents[0].diff(commit).patches
    end

    it { Gitlab::Git::Diff.new(@diffs[0]).submodule?.should == false }
    it { Gitlab::Git::Diff.new(@diffs[1]).submodule?.should == true }
  end
end
