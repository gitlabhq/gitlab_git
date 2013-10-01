require "spec_helper"

describe Gitlab::Git::Commit do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:commit) { Gitlab::Git::Commit.last(repository) }

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

      @tree = double

      @parents = [ double(id: "8716fc78f3c65bbf7bcf7b574febd583bc5d2812") ]

      @raw_commit = double(
        id: "bcf03b5de6abcf03b5de6c",
        author: @author,
        committer: @committer,
        committed_date: Date.today.prev_day,
        authored_date: Date.today.prev_day,
        tree: @tree,
        parents: @parents,
        message: 'Refactoring specs'
      )

      @commit = Gitlab::Git::Commit.new(@raw_commit)
    end

    it { @commit.short_id.should == "bcf03b5de6a" }
    it { @commit.id.should == @raw_commit.id }
    it { @commit.sha.should == @raw_commit.id }
    it { @commit.safe_message.should == @raw_commit.message }
    it { @commit.created_at.should == @raw_commit.committed_date }
    it { @commit.date.should == @raw_commit.committed_date }
    it { @commit.author_email.should == @author.email }
    it { @commit.author_name.should == @author.name }
    it { @commit.committer_name.should == @committer.name }
    it { @commit.committer_email.should == @committer.email }
    it { @commit.different_committer?.should be_true }
    it { @commit.parents.should == @parents }
    it { @commit.parent_id.should == @parents.first.id }
    it { @commit.no_commit_message.should == "--no commit message" }
    it { @commit.tree.should == @tree }
  end

  context 'Class methods' do
    describe :find do
      it "should return first head commit if without params" do
        Gitlab::Git::Commit.last(repository).id.should == repository.raw.commits.first.id
      end

      it "should return valid commit" do
        Gitlab::Git::Commit.find(repository, ValidCommit::ID).should be_valid_commit
      end

      it "should return nil" do
        Gitlab::Git::Commit.find(repository, "+123_4532530XYZ").should be_nil
      end
    end

    describe :last_for_path do
      context 'no path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master') }

        its(:id) { should == 'bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a' }
      end

      context 'path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master', 'db') }

        its(:id) { should == '621bfdb4aa6c5ef2b031f7c4fb7753eb80d7a5b5' }
      end

      context 'ref + path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, ValidCommit::ID, 'config') }

        its(:id) { should == '215a01f63ccdc085f75a48f6f7ab6f2b15b5852c' }
      end
    end


    describe "where" do
      subject do
        commits = Gitlab::Git::Commit.where(
          repo: repository,
          ref: 'master',
          path: 'app',
          limit: 3,
          offset: 1
        )

        commits.map { |c| c.id }
      end

      it { should have(3).elements }
      it { should include("8716fc78f3c65bbf7bcf7b574febd583bc5d2812") }
      it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
    end

    describe :between do
      subject do
        commits = Gitlab::Git::Commit.between(repository,
                                              "3a4b4fb4cde7809f033822a171b9feae19d41fff",
                                              "8470d70da67355c9c009e4401746b1d5410af2e3")
        commits.map { |c| c.id }
      end

      it { should have(3).elements }
      it { should include("f0f14c8eaba69ebddd766498a9d0b0e79becd633") }
      it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
    end

    describe :find_all do
      context 'max_count' do
        subject do
          commits = Gitlab::Git::Commit.find_all(
            repository,
            max_count: 50
          )

          commits.map { |c| c.id }
        end

        it { should have(50).elements }
        it { should include("8716fc78f3c65bbf7bcf7b574febd583bc5d2812") }
        it { should include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
        it { should include("0e7c3fc61e75fd7de0a68d9966b5b2142b23739f") }
      end

      context 'ref + max_count + skip' do
        subject do
          commits = Gitlab::Git::Commit.find_all(
            repository,
            ref: 'master',
            max_count: 50,
            skip: 1
          )

          commits.map { |c| c.id }
        end

        it { should have(50).elements }
        it { should include("8716fc78f3c65bbf7bcf7b574febd583bc5d2812") }
        it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
        it { should_not include("0e7c3fc61e75fd7de0a68d9966b5b2142b23739f") }
      end

      context 'contains master_bk_2 + max_count' do
        subject do
          commits = Gitlab::Git::Commit.find_all(
            repository,
            contains: 'master_bk_2',
            max_count: 50
          )

          commits.map { |c| c.id }
        end

        it { should have(50).elements }
        it { should_not include("8716fc78f3c65bbf7bcf7b574febd583bc5d2812") }
        it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
        it { should include("0e7c3fc61e75fd7de0a68d9966b5b2142b23739f") }
      end

      context 'contains master_bk_2^ + max_count' do
        subject do
          commits = Gitlab::Git::Commit.find_all(
            repository,
            contains: 'master_bk_2^',
            max_count: 50
          )

          commits.map { |c| c.id }
        end

        it { should have(50).elements }
        it { should include("8716fc78f3c65bbf7bcf7b574febd583bc5d2812") }
        it { should include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
        it { should include("0e7c3fc61e75fd7de0a68d9966b5b2142b23739f") }
      end
    end
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

  describe :has_zero_stats? do
    it { commit.has_zero_stats?.should == false }
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

  describe :diffs do
    subject { commit.diffs }

    it { should be_kind_of Array }
    its(:size) { should eq(2) }
    its(:first) { should be_kind_of Gitlab::Git::Diff }
  end

  describe :ref_names do
    let(:commit) { Gitlab::Git::Commit.find(repository, 'master') }
    subject { commit.ref_names(repository) }

    it { should have(3).elements }
    it { should include("master") }
    it { should_not include("master_bk_2") }
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
