require "spec_helper"

describe Gitlab::Git::Stats do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  before do
    @stats = Gitlab::Git::Stats.new(repository, 'master')
  end

  describe :authors do
    let(:author) { @stats.authors.first }

    it { author.name.should == 'Dmitriy Zaporozhets' }
    it { author.email.should == 'dmitriy.zaporozhets@gmail.com' }
    it { author.commits.should == 13 }
  end

  describe :graph do
    let(:graph) { @stats.graph }

    it { graph.labels.should include Date.today.strftime('%b %d') }
    it { graph.commits.should be_kind_of(Array) }
    it { graph.weeks.should == 4 }
  end

  it { @stats.commits_count.should == 13 }
  it { @stats.files_count.should == 31 }
end
