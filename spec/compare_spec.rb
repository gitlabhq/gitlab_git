require "spec_helper"

describe Gitlab::Git::Compare do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::Commit::ID) }

  describe :commits do
    subject do
      compare.commits.map(&:id)
    end

    it { should have(8).elements }
    it { should include(SeedRepo::Commit::PARENT_ID) }
    it { should_not include(SeedRepo::BigCommit::PARENT_ID) }
  end

  describe :diffs do
    subject do
      compare.diffs.map(&:new_path)
    end

    it { should have(10).elements }
    it { should include('files/ruby/popen.rb') }
    it { should_not include('LICENSE') }
    it { compare.timeout.should be_false }
    it { compare.empty_diff?.should be_false }
  end

  describe 'non-existing refs' do
    let(:compare) { Gitlab::Git::Compare.new(repository, 'no-such-branch', '1234567890') }

    it { compare.commits.should be_empty }
    it { compare.diffs.should be_empty }
  end
end
