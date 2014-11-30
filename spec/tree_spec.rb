require "spec_helper"

describe Gitlab::Git::Tree do
  context :repo do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
    let(:tree) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID) }

    it { expect(tree).to be_kind_of Array }
    it { tree.empty? == false }
    it { tree.select(&:dir?).size == 2 }
    it { tree.select(&:file?).size == 10 }
    it { tree.select(&:submodule?).size == 2 }

    describe :dir do
      let(:dir) { tree.select(&:dir?).first }

      it { expect(dir).to be_kind_of Gitlab::Git::Tree }
      it { dir.id == '3c122d2b7830eca25235131070602575cf8b41a1' }
      it { dir.commit_id == SeedRepo::Commit::ID }
      it { dir.name == 'encoding' }
      it { dir.path == 'encoding' }

      context :subdir do
        let(:subdir) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files').first }

        it { expect(subdir).to be_kind_of Gitlab::Git::Tree }
        it { subdir.id == 'a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba' }
        it { subdir.commit_id == SeedRepo::Commit::ID }
        it { subdir.name == 'html' }
        it { subdir.path == 'files/html' }
      end

      context :subdir_file do
        let(:subdir_file) { Gitlab::Git::Tree.where(repository, SeedRepo::Commit::ID, 'files/ruby').first }

        it { expect(subdir_file).to be_kind_of Gitlab::Git::Tree }
        it { subdir_file.id == '7e3e39ebb9b2bf433b4ad17313770fbe4051649c' }
        it { subdir_file.commit_id == SeedRepo::Commit::ID }
        it { subdir_file.name == 'popen.rb' }
        it { subdir_file.path == 'files/ruby/popen.rb' }
      end
    end

    describe :file do
      let(:file) { tree.select(&:file?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { file.id == 'dfaa3f97ca337e20154a98ac9d0be76ddd1fcc82' }
      it { file.commit_id == SeedRepo::Commit::ID }
      it { file.name == '.gitignore' }
    end

    describe :readme do
      let(:file) { tree.select(&:readme?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { file.name == 'README.md' }
    end

    describe :contributing do
      let(:file) { tree.select(&:contributing?).first }

      it { expect(file).to be_kind_of Gitlab::Git::Tree }
      it { file.name == 'CONTRIBUTING.md' }
    end

    describe :submodule do
      let(:submodule) { tree.select(&:submodule?).first }

      it { expect(submodule).to be_kind_of Gitlab::Git::Tree }
      it { submodule.id == '79bceae69cb5750d6567b223597999bfa91cb3b9' }
      it { submodule.commit_id == '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
      it { submodule.name == 'gitlab-shell' }
    end
  end
end
