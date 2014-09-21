require 'spec_helper'

describe Gitlab::Git::GitStats do
  describe "#parsed_log" do
    let(:stats) { Gitlab::Git::GitStats.new(nil, nil) }

    before(:each) do
      stats.stub(:log).and_return("anything")
    end

    context "LogParser#parse_log returns 'test'" do
      it "returns 'test'" do
        Gitlab::Git::LogParser.stub(:parse_log).and_return("test")
        stats.parsed_log.should eq("test")
      end
    end
  end

  describe "#log" do
    let(:repo) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
    let(:gs) { Gitlab::Git::GitStats.new(repo, repo.root_ref) }

    context "repo.git.native returns 'test'" do
      it "returns 'test'" do
        lines = gs.log.split("\n")
        lines.first.should eq("Dmitriy Zaporozhets")

        lines[4].should include("2 files changed")
        lines[4].should include("4 insertions")
        lines[4].should_not include("deletions")

        lines[9].should include("2 files changed")
        lines[9].should include("11 insertions")
        lines[9].should include("6 deletions")
      end
    end
  end
end
