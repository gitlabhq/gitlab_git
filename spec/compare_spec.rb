require "spec_helper"

describe Gitlab::Git::Compare do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:compare) { Gitlab::Git::Compare.new(repository, SeedRepo::BigCommit::ID, SeedRepo::Commit::ID) }

  describe :commits do
    subject do
      compare.commits.map(&:id)
    end

    it { subject.size == 8 }
    it { should include(SeedRepo::Commit::PARENT_ID) }
    it { should_not include(SeedRepo::BigCommit::PARENT_ID) }
  end

  describe :diffs do
    subject do
      compare.diffs.map(&:new_path)
    end

    it { subject.size == 10 }
    it { should include('files/ruby/popen.rb') }
    it { should_not include('LICENSE') }
    it { compare.timeout == false }
    it { compare.empty_diff? == false }
  end

  describe 'non-existing refs' do
    let(:compare) { Gitlab::Git::Compare.new(repository, 'no-such-branch', '1234567890') }

    it { expect(compare.commits).to be_empty }
    it { expect(compare.diffs).to be_empty }
  end
end
