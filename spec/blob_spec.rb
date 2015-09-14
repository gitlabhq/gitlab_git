# encoding: UTF-8

require "spec_helper"

describe Gitlab::Git::Blob do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe :find do
    context 'file in subdir' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb") }

      it { blob.id.should == SeedRepo::RubyBlob::ID }
      it { blob.name.should == SeedRepo::RubyBlob::NAME }
      it { blob.path.should == "files/ruby/popen.rb" }
      it { blob.commit_id.should == SeedRepo::Commit::ID }
      it { blob.data[0..10].should == SeedRepo::RubyBlob::CONTENT[0..10] }
      it { blob.size.should == 669 }
      it { blob.mode.should == "100644" }
    end

    context 'file in root' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, ".gitignore") }

      it { blob.id.should == "dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82" }
      it { blob.name.should == ".gitignore" }
      it { blob.path.should == ".gitignore" }
      it { blob.commit_id.should == SeedRepo::Commit::ID }
      it { blob.data[0..10].should == "*.rbc\n*.sas" }
      it { blob.size.should == 241 }
      it { blob.mode.should == "100644" }
    end

    context 'file in root with leading slash' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "/.gitignore") }

      it { blob.id.should == "dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82" }
      it { blob.name.should == ".gitignore" }
      it { blob.path.should == ".gitignore" }
      it { blob.commit_id.should == SeedRepo::Commit::ID }
      it { blob.data[0..10].should == "*.rbc\n*.sas" }
      it { blob.size.should == 241 }
      it { blob.mode.should == "100644" }
    end

    context 'non-exist file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "missing.rb") }

      it { blob.should be_nil }
    end

    context 'six submodule' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, 'six') }

      it { blob.id.should == '409f37c4f05865e4fb208c771485f211a22c4c2d' }
      it { blob.data.should == '' }
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    it { raw_blob.id.should == SeedRepo::RubyBlob::ID }
    it { raw_blob.data[0..10].should == "require \'fi" }
    it { raw_blob.size.should == 669 }
  end

  describe 'encoding' do
    context 'file with russian text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/russian.rb") }

      it { blob.name.should == "russian.rb" }
      it { blob.data.lines.first.should == "Хороший файл" }
      it { blob.size.should == 23 }
      it { blob.mode.should == "100755" }
    end

    context 'file with Chinese text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/テスト.txt") }

      it { blob.name.should == "テスト.txt" }
      it { blob.data.should include("これはテスト") }
      it { blob.size.should == 340 }
      it { blob.mode.should == "100755" }
    end
  end

  describe 'mode' do
    context 'file regular' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/ruby/regex.rb'
        )
      end

      it { blob.name.should == 'regex.rb' }
      it { blob.path.should == 'files/ruby/regex.rb' }
      it { blob.size.should == 1200 }
      it { blob.mode.should == "100644" }
    end

    context 'file binary' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/executables/ls'
        )
      end

      it { blob.name.should == 'ls' }
      it { blob.path.should == 'files/executables/ls' }
      it { blob.size.should == 110080 }
      it { blob.mode.should == "100755" }
    end

    context 'file symlink to regular' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/links/ruby-style-guide.md'
        )
      end

      it { blob.name.should == 'ruby-style-guide.md' }
      it { blob.path.should == 'files/links/ruby-style-guide.md' }
      it { blob.size.should == 31 }
      it { blob.mode.should == "120000" }
    end

    context 'file symlink to binary' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6',
          'files/links/touch'
        )
      end

      it { blob.name.should == 'touch' }
      it { blob.path.should == 'files/links/touch' }
      it { blob.size.should == 20 }
      it { blob.mode.should == "120000" }
    end
  end

  describe :create do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

    let(:commit_options) do
      options = {
         file: {
           content: 'Lorem ipsum...',
           path: 'documents/story.txt'
         },
         author: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         committer: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         commit: {
           message: 'Wow such commit',
           branch: 'feature'
         }
      }
    end

    let!(:commit_sha) { Gitlab::Git::Blob.commit(repository, commit_options) }
    let!(:commit) { repository.lookup(commit_sha) }

    it 'should add file with commit' do
      # Commit message valid
      commit.message.should == 'Wow such commit'

      tree = commit.tree.to_a.find { |tree| tree[:name] == 'documents' }

      # Directory was created
      tree[:type].should == :tree

      # File was created
      repository.lookup(tree[:oid]).first[:name].should == 'story.txt'
    end
  end

  describe :remove do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

    let(:commit_options) do
      options = {
         file: {
           path: 'README.md'
         },
         author: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         committer: {
           email: 'user@example.com',
           name: 'Test User',
           time: Time.now
         },
         commit: {
           message: 'Remove readme',
           branch: 'feature'
         }
      }
    end

    let!(:commit_sha) { Gitlab::Git::Blob.remove(repository, commit_options) }
    let!(:commit) { repository.lookup(commit_sha) }

    it 'should remove file with commit' do
      # Commit message valid
      commit.message.should == 'Remove readme'

      # File was removed
      commit.tree.to_a.any? do |tree|
        tree[:name] == 'README.md'
      end.should be_false
    end
  end
end
