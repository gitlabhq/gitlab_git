require "spec_helper"

describe Gitlab::Git::Tree do
  context :repo do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
    let(:tree) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID) }

    it { tree.should be_kind_of Array }
    it { tree.empty?.should be_false }
    it { tree.select(&:dir?).size.should == 2 }
    it { tree.select(&:file?).size.should == 10 }
    it { tree.select(&:submodule?).size.should == 2 }

    describe :dir do
      let(:dir) { tree.select(&:dir?).first }

      it { dir.should be_kind_of Gitlab::Git::Tree }
      it { dir.id.should == '3c122d2b7830eca25235131070602575cf8b41a1' }
      it { dir.commit_id.should == SeedRepo::Commit::ID }
      it { dir.name.should == 'encoding' }
      it { dir.path.should == 'encoding' }

      context :subdir do
        let(:subdir) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files').first }

        it { subdir.should be_kind_of Gitlab::Git::Tree }
        it { subdir.id.should == 'a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba' }
        it { subdir.commit_id.should == SeedRepo::Commit::ID }
        it { subdir.name.should == 'html' }
        it { subdir.path.should == 'files/html' }
      end

      context :subdir_file do
        let(:subdir_file) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }

        it { subdir_file.should be_kind_of Gitlab::Git::Tree }
        it { subdir_file.id.should == '7e3e39ebb9b2bf433b4ad17313770fbe4051649c' }
        it { subdir_file.commit_id.should == SeedRepo::Commit::ID }
        it { subdir_file.name.should == 'popen.rb' }
        it { subdir_file.path.should == 'files/ruby/popen.rb' }
      end
    end

    describe :file do
      let(:file) { tree.select(&:file?).first }

      it { file.should be_kind_of Gitlab::Git::Tree }
      it { file.id.should == 'dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82' }
      it { file.commit_id.should == SeedRepo::Commit::ID }
      it { file.name.should == '.gitignore' }
    end

    describe :readme do
      let(:file) { tree.select(&:readme?).first }

      it { file.should be_kind_of Gitlab::Git::Tree }
      it { file.name.should == 'README.md' }
    end

    describe :contributing do
      let(:file) { tree.select(&:contributing?).first }

      it { file.should be_kind_of Gitlab::Git::Tree }
      it { file.name.should == 'CONTRIBUTING.md' }
    end

    describe :submodule do
      let(:submodule) { tree.select(&:submodule?).first }

      it { submodule.should be_kind_of Gitlab::Git::Tree }
      it { submodule.id.should == '79bceae69cb5750d6567b223597999bfa91cb3b9' }
      it { submodule.commit_id.should == '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
      it { submodule.name.should == 'gitlab-shell' }
    end
  end
end
