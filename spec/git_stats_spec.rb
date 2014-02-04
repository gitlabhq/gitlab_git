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
    let(:repo) { double(Gitlab::Git::Repository).as_null_object }
    let(:gs) { Gitlab::Git::GitStats.new(repo.raw, repo.root_ref) }

    context "repo.git.run returns 'test'" do
      it "returns 'test'" do
        repo.raw.git.stub(:run).and_return("test")
        gs.log.should eq("test")
      end
    end
  end
end
