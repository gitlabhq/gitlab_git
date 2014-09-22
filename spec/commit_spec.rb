require "spec_helper"

describe Gitlab::Git::Commit do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:commit) { Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID) }
  let(:rugged_commit) do
    repository.rugged.lookup(SeedRepo::Commit::ID)
  end

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

      @parents = [ double(id: "874797c3a73b60d2187ed6e2fcabd289ff75171e") ]

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
        Gitlab::Git::Commit.find(repository, SeedRepo::Commit::ID).should be_valid_commit
      end

      it "should return valid commit for tag" do
        Gitlab::Git::Commit.find(repository, 'v1.0.0').id.should == '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      end

      it "should return nil" do
        Gitlab::Git::Commit.find(repository, "+123_4532530XYZ").should be_nil
      end
    end

    describe :last_for_path do
      context 'no path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master') }

        its(:id) { should == SeedRepo::LastCommit::ID }
      end

      context 'path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, 'master', 'files') }

        its(:id) { should == SeedRepo::Commit::ID }
      end

      context 'ref + path' do
        subject { Gitlab::Git::Commit.last_for_path(repository, SeedRepo::Commit::ID, 'encoding') }

        its(:id) { should == SeedRepo::BigCommit::ID }
      end
    end


    describe "where" do
      subject do
        commits = Gitlab::Git::Commit.where(
          repo: repository,
          ref: 'master',
          path: 'files',
          limit: 3,
          offset: 1
        )

        commits.map { |c| c.id }
      end

      it { should have(3).elements }
      it { should include("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
      it { should_not include(SeedRepo::Commit::ID) }
    end

    describe :between do
      subject do
        commits = Gitlab::Git::Commit.between(repository, SeedRepo::Commit::PARENT_ID, SeedRepo::Commit::ID)
        commits.map { |c| c.id }
      end

      it { should have(1).elements }
      it { should include(SeedRepo::Commit::ID) }
      it { should_not include(SeedRepo::FirstCommit::ID) }
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

        it { should have(15).elements }
        it { should include(SeedRepo::Commit::ID) }
        it { should include(SeedRepo::Commit::PARENT_ID) }
        it { should include(SeedRepo::FirstCommit::ID) }
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

        it { should have(12).elements }
        it { should include(SeedRepo::Commit::ID) }
        it { should include(SeedRepo::FirstCommit::ID) }
        it { should_not include(SeedRepo::LastCommit::ID) }
      end

      context 'contains feature + max_count' do
        subject do
          commits = Gitlab::Git::Commit.find_all(
            repository,
            contains: 'feature',
            max_count: 7
          )

          commits.map { |c| c.id }
        end

        it { should have(7).elements }

        it { should_not include(SeedRepo::Commit::PARENT_ID) }
        it { should_not include(SeedRepo::Commit::ID) }
        it { should include(SeedRepo::BigCommit::ID) }
      end
    end
  end

  describe :init_from_rugged do
    let(:gitlab_commit) { Gitlab::Git::Commit.new(rugged_commit) }
    subject { gitlab_commit }

    its(:id) { should == SeedRepo::Commit::ID }
  end

  describe :init_from_hash do
    let(:commit) { Gitlab::Git::Commit.new(sample_commit_hash) }
    subject { commit }

    its(:id) { should == sample_commit_hash[:id]}
    its(:message) { should == sample_commit_hash[:message]}
  end

  describe :stats do
    subject { commit.stats }

    its(:additions) { should eq(11) }
    its(:deletions) { should eq(6) }
  end

  describe :to_diff do
    subject { commit.to_diff }

    it { should_not include "From #{SeedRepo::Commit::ID}" }
    it { should include 'diff --git a/files/ruby/popen.rb b/files/ruby/popen.rb'}
  end

  describe :has_zero_stats? do
    it { commit.has_zero_stats?.should == false }
  end

  describe :to_patch do
    subject { commit.to_patch }

    it { should include "From #{SeedRepo::Commit::ID}" }
    it { should include 'diff --git a/files/ruby/popen.rb b/files/ruby/popen.rb'}
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

    it { should have(2).elements }
    it { should include("master") }
    it { should_not include("feature") }
  end

  def sample_commit_hash
    {
      author_email: "dmitriy.zaporozhets@gmail.com",
      author_name: "Dmitriy Zaporozhets",
      authored_date: "2012-02-27 20:51:12 +0200",
      committed_date: "2012-02-27 20:51:12 +0200",
      committer_email: "dmitriy.zaporozhets@gmail.com",
      committer_name: "Dmitriy Zaporozhets",
      id: SeedRepo::Commit::ID,
      message: "tree css fixes",
      parent_ids: ["874797c3a73b60d2187ed6e2fcabd289ff75171e"]
    }
  end
end
