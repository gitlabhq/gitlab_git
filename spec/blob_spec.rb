require "spec_helper"

describe Gitlab::Git::Blob do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
  let(:blob) { Gitlab::Git::Blob.find(repository, ValidCommit::ID, "app/models/project.rb") }

  it { blob.id.should == "b59dcd80c874a106258b5b1d30050360151fef2d" }
  it { blob.name.should == "project.rb" }
  it { blob.path.should == "app/models/project.rb" }
  it { blob.commit_id.should == ValidCommit::ID }
  it { blob.data[0..10].should == "require \"gr" }
  it { blob.size.should == 10049  }
end
