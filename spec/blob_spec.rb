# encoding: utf-8

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

    context 'large file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, 'files/images/6049019_460s.jpg') }
      let(:blob_size) { 111803 }

      it { blob.size.should == blob_size }
      it { blob.data.length.should == Gitlab::Git::Blob::DATA_SNIPPET_SIZE }

      it 'check that this test is sane' do
        blob.size.should > Gitlab::Git::Blob::DATA_SNIPPET_SIZE
      end

      it 'can load all data' do
        blob.load_all_data!(repository)
        blob.data.length.should == blob_size
      end
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    it { raw_blob.id.should == SeedRepo::RubyBlob::ID }
    it { raw_blob.data[0..10].should == "require \'fi" }
    it { raw_blob.size.should == 669 }

    context 'large file' do
      let(:blob) { Gitlab::Git::Blob.raw(repository, '08cf843fd8fe1c50757df0a13fcc44661996b4df') }
      let(:blob_size) { 111803 }

      it { blob.size.should == blob_size }
      it { blob.data.length.should == Gitlab::Git::Blob::DATA_SNIPPET_SIZE }
      
      it 'check that this test is sane' do
        blob.size.should > Gitlab::Git::Blob::DATA_SNIPPET_SIZE
      end
    end
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
           branch: 'fix-mode'
         }
      }
    end

    let(:commit_sha) { Gitlab::Git::Blob.commit(repository, commit_options) }
    let(:commit) { repository.lookup(commit_sha) }

    it 'should add file with commit' do
      # Commit message valid
      commit.message.should == 'Wow such commit'

      tree = commit.tree.to_a.find { |tree| tree[:name] == 'documents' }

      # Directory was created
      tree[:type].should == :tree

      # File was created
      repository.lookup(tree[:oid]).first[:name].should == 'story.txt'
    end

    describe 'reject updates' do
      it 'should reject updates' do
        commit_options[:file][:update] = false
        commit_options[:file][:path] = 'files/executables/ls'

        expect{ commit_sha }.to raise_error('Filename already exists; update not allowed')
      end
    end

    describe 'file modes' do
      it 'should preserve file modes with commit' do
        commit_options[:file][:path] = 'files/executables/ls'

        entry = Gitlab::Git::Blob::find_entry_by_path(repository, commit.tree.oid, commit_options[:file][:path])
        expect(entry[:filemode]).to eq(0100755)
      end
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

  describe :lfs_pointers do
    context 'file a valid lfs pointer' do
      let(:blob) do
        Gitlab::Git::Blob.find(
          repository,
          '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
          'files/lfs/image.jpg'
        )
      end

      it { blob.lfs_pointer?.should == true }
      it { blob.lfs_oid.should == "4206f951d2691c78aac4c0ce9f2b23580b2c92cdcc4336e1028742c0274938e0" }
      it { blob.lfs_size.should == "19548" }
      it { blob.id.should == "f4d76af13003d1106be7ac8c5a2a3d37ddf32c2a" }
      it { blob.name.should == "image.jpg" }
      it { blob.path.should == "files/lfs/image.jpg" }
      it { blob.size.should == 130 }
      it { blob.mode.should == "100644" }
    end

    describe 'file an invalid lfs pointer' do
      context 'with correct version header but incorrect size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/archive-invalid.tar'
          )
        end

        it { blob.lfs_pointer?.should == false }
        it { blob.lfs_oid.should == nil }
        it { blob.lfs_size.should == nil }
        it { blob.id.should == "f8a898db217a5a85ed8b3d25b34c1df1d1094c46" }
        it { blob.name.should == "archive-invalid.tar" }
        it { blob.path.should == "files/lfs/archive-invalid.tar" }
        it { blob.size.should == 43 }
        it { blob.mode.should == "100644" }
      end

      context 'with correct version header and size but incorrect size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/picture-invalid.png'
          )
        end

        it { blob.lfs_pointer?.should == false }
        it { blob.lfs_oid.should == nil }
        it { blob.lfs_size.should == "1575078" }
        it { blob.id.should == "5ae35296e1f95c1ef9feda1241477ed29a448572" }
        it { blob.name.should == "picture-invalid.png" }
        it { blob.path.should == "files/lfs/picture-invalid.png" }
        it { blob.size.should == 57 }
        it { blob.mode.should == "100644" }
      end

      context 'with correct version header and size but invalid size and oid' do
        let(:blob) do
          Gitlab::Git::Blob.find(
            repository,
            '33bcff41c232a11727ac6d660bd4b0c2ba86d63d',
            'files/lfs/file-invalid.zip'
          )
        end

        it { blob.lfs_pointer?.should == false }
        it { blob.lfs_oid.should == nil }
        it { blob.lfs_size.should == nil }
        it { blob.id.should == "d831981bd876732b85a1bcc6cc01210c9f36248f" }
        it { blob.name.should == "file-invalid.zip" }
        it { blob.path.should == "files/lfs/file-invalid.zip" }
        it { blob.size.should == 60 }
        it { blob.mode.should == "100644" }
      end
    end
  end
end
