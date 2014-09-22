require "spec_helper"

describe Gitlab::Git::Blame do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:blame) do
    Gitlab::Git::Blame.new(repository, SeedRepo::Commit::ID, "CONTRIBUTING.md")
  end

  context "each count" do
    it do
      blame.each do |commit, hunk_lines|
        commit.should be_kind_of Gitlab::Git::Commit
        hunk_lines.first.should == "# Contribute to GitLab"
      end
    end
  end
end
