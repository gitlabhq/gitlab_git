# encoding: UTF-8

require "spec_helper"

describe Gitlab::Git::Blob do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe :find do
    context 'file in subdir' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "files/ruby/popen.rb") }

      it { blob.id == SeedRepo::RubyBlob::ID }
      it { blob.name == SeedRepo::RubyBlob::NAME }
      it { blob.path == "files/ruby/popen.rb" }
      it { blob.commit_id == SeedRepo::Commit::ID }
      it { blob.data[0..10] == SeedRepo::RubyBlob::CONTENT[0..10] }
      it { blob.size == 669  }
    end

    context 'file in root' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, ".gitignore") }

      it { blob.id == "dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82" }
      it { blob.name == ".gitignore" }
      it { blob.path == ".gitignore" }
      it { blob.commit_id == SeedRepo::Commit::ID }
      it { blob.data[0..10] == "*.rbc\n*.sas" }
      it { blob.size == 241  }
    end

    context 'non-exist file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "missing.rb") }

      it { blob == nil }
    end

    context 'six submodule' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, 'six') }

      it { blob.id == '409f37c4f05865e4fb208c771485f211a22c4c2d' }
      it { blob.data == '' }
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    it { raw_blob.id == SeedRepo::RubyBlob::ID }
    it { raw_blob.data[0..10] == "require \'fi" }
    it { raw_blob.size == 669  }
  end

  describe 'encoding' do
    context 'file with russian text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/russian.rb") }

      it { blob.name == "russian.rb" }
      it { blob.data.lines.first == "Хороший файл" }
      it { blob.size == 23  }
    end

    context 'file with Chinese text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/テスト.txt") }

      it { blob.name == "テスト.txt" }
      it { expect(blob.data).to include("これはテスト") }
      it { blob.size == 340  }
    end
  end
end
