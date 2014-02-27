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
      it { blob.size.should == 669  }
    end

    context 'file in root' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, ".gitignore") }

      it { blob.id.should == "dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82" }
      it { blob.name.should == ".gitignore" }
      it { blob.path.should == ".gitignore" }
      it { blob.commit_id.should == SeedRepo::Commit::ID }
      it { blob.data[0..10].should == "*.rbc\n*.sas" }
      it { blob.size.should == 241  }
    end

    context 'non-exist file' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "missing.rb") }

      it { blob.should be_nil }
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, SeedRepo::RubyBlob::ID) }
    it { raw_blob.id.should == SeedRepo::RubyBlob::ID }
    it { raw_blob.data[0..10].should == "require \'fi" }
    it { raw_blob.size.should == 669  }
  end

  describe 'encoding' do
    context 'file with russian text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/russian.rb") }

      it { blob.name.should == "russian.rb" }
      it { blob.data.lines.first.should == "Хороший файл" }
      it { blob.size.should == 23  }
    end

    context 'file with Chinese text' do
      let(:blob) { Gitlab::Git::Blob.find(repository, SeedRepo::Commit::ID, "encoding/テスト.txt") }

      it { blob.name.should == "テスト.txt" }
      it { blob.data.should include("これはテスト") }
      it { blob.size.should == 340  }
    end
  end
end
