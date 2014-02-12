require "spec_helper"

describe Gitlab::Git::Compare do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:compare) { Gitlab::Git::Compare.new(repository,
                                           "3a4b4fb4cde7809f033822a171b9feae19d41fff",
                                           "8470d70da67355c9c009e4401746b1d5410af2e3") }

  describe :commits do
    subject do
      compare.commits.map(&:id)
    end

    it { should have(3).elements }
    it { should include("f0f14c8eaba69ebddd766498a9d0b0e79becd633") }
    it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
  end

  describe :diffs do
    subject do
      compare.diffs.map(&:new_path)
    end

    it { should have(19).elements }
    it { should include('app/assets/javascripts/application.js') }
    it { should_not include('Gemfile') }
    it { compare.timeout.should be_false }
    it { compare.empty_diff?.should be_false }
  end
end
