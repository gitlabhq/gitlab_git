require "spec_helper"

describe Gitlab::Git::Commit do
  let(:repository) { Gitlab::Git::Repository.new('gitlabhq', 'master') }
  let(:commit) { repository.commit }

  describe "Commit info" do
    before do
      @committer = double(
        email: 'mike@smith.com',
        name: 'Mike Smith'
      )

      @author = double(
        email: 'john@smith.com',
        name: 'John Smith'
      )

      @raw_commit = double(
        id: "bcf03b5de6abcf03b5de6c",
        author: @author,
        committer: @committer,
        committed_date: Date.today.prev_day,
        authored_date: Date.today.prev_day,
        parents: [],
        message: 'Refactoring specs'
      )

      @commit = Gitlab::Git::Commit.new(@raw_commit)
    end

    it { @commit.short_id.should == "bcf03b5de6a" }
    it { @commit.safe_message.should == @raw_commit.message }
    it { @commit.created_at.should == @raw_commit.committed_date }
    it { @commit.author_email.should == @author.email }
    it { @commit.author_name.should == @author.name }
    it { @commit.committer_name.should == @committer.name }
    it { @commit.committer_email.should == @committer.email }
    it { @commit.different_committer?.should be_true }
  end

  describe :init_from_hash do
    let(:commit) { Gitlab::Git::Commit.new(sample_commit_hash) }
    subject { commit }

    its(:id) { should == sample_commit_hash[:id]}
    its(:message) { should == sample_commit_hash[:message]}
  end

  describe :stats do
    subject { commit.stats }

    its(:additions) { should eq(2) }
    its(:deletions) { should eq(1) }
  end

  describe :to_diff do
    subject { commit.to_diff }

    it { should_not include "From bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" }
    it { should include 'diff --git a/app/assets/stylesheets/tree.scss b/app/assets/stylesheets/tree.scss'}
  end

  describe :to_patch do
    subject { commit.to_patch }

    it { should include "From bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" }
    it { should include 'diff --git a/app/assets/stylesheets/tree.scss b/app/assets/stylesheets/tree.scss'}
  end

  describe :to_hash do
    let(:hash) { commit.to_hash }
    subject { hash }

    it { should be_kind_of Hash }
    its(:keys) { should =~ sample_commit_hash.keys }
  end

  def sample_commit_hash
    {
      author_email: "dmitriy.zaporozhets@gmail.com",
      author_name: "Dmitriy Zaporozhets",
      authored_date: "2012-02-27 20:51:12 +0200",
      committed_date: "2012-02-27 20:51:12 +0200",
      committer_email: "dmitriy.zaporozhets@gmail.com",
      committer_name: "Dmitriy Zaporozhets",
      id: "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a",
      message: "tree css fixes",
      parent_ids: ["8716fc78f3c65bbf7bcf7b574febd583bc5d2812"]
    }
  end
end
