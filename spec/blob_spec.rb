require "spec_helper"

describe Gitlab::Git::Blob do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  describe :find do
    context 'file in subdir' do
      let(:blob) { Gitlab::Git::Blob.find(repository, ValidCommit::ID, "app/models/project.rb") }

      it { blob.id.should == "b59dcd80c874a106258b5b1d30050360151fef2d" }
      it { blob.name.should == "project.rb" }
      it { blob.path.should == "app/models/project.rb" }
      it { blob.commit_id.should == ValidCommit::ID }
      it { blob.data[0..10].should == "require \"gr" }
      it { blob.size.should == 10049  }
    end

    context 'file in root' do
      let(:blob) { Gitlab::Git::Blob.find(repository, ValidCommit::ID, "config.ru") }

      it { blob.id.should == "5ef2a0289fee14259ff60c5a460fc97690443efd" }
      it { blob.name.should == "config.ru" }
      it { blob.path.should == "config.ru" }
      it { blob.commit_id.should == ValidCommit::ID }
      it { blob.data[0..10].should == "# This file" }
      it { blob.size.should == 156  }
    end
  end

  describe :raw do
    let(:raw_blob) { Gitlab::Git::Blob.raw(repository, "b59dcd80c874a106258b5b1d30050360151fef2d") }
    it { raw_blob.id.should == "b59dcd80c874a106258b5b1d30050360151fef2d" }
    it { raw_blob.data[0..10].should == "require \"gr" }
    it { raw_blob.size.should == 10049  }
  end
end
