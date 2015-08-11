require "spec_helper"

describe Gitlab::Git::Blame do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:blame) do
    Gitlab::Git::Blame.new(repository, SeedRepo::Commit::ID, "CONTRIBUTING.md")
  end

  context "each count" do
    it do
      data = []
      blame.each do |commit, line|
        data << {
          commit: commit,
          line: line
        }
      end

      data.size.should == 95
      data.first[:commit].should be_kind_of Gitlab::Git::Commit
      data.first[:line].should == "# Contribute to GitLab"
    end
  end
end
