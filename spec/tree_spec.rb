require "spec_helper"

describe Gitlab::Git::Tree do
  context :repo do
    let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }
    let(:tree) { Gitlab::Git::Tree.where(repository, ValidCommit::ID) }

    it { tree.should be_kind_of Array }
    it { tree.empty?.should be_false }
    it { tree.select(&:dir?).size.should == 10 }
    it { tree.select(&:file?).size.should == 16 }
    it { tree.select(&:submodule?).size.should == 0 }

    describe :dir do
      let(:dir) { tree.select(&:dir?).first }

      it { dir.should be_kind_of Gitlab::Git::Tree }
      it { dir.id.should == 'ba18d73c8fa3a326a5779b75bda0384dfb360240' }
      it { dir.commit_id.should == ValidCommit::ID }
      it { dir.name.should == 'app' }
      it { dir.path.should == 'app' }

      context :subdir do
        let(:subdir) { Gitlab::Git::Tree.where(repository, ValidCommit::ID, dir.name).first }

        it { subdir.should be_kind_of Gitlab::Git::Tree }
        it { subdir.id.should == '38f45392ae61f0effa84048f208a81019cc306bb' }
        it { subdir.commit_id.should == ValidCommit::ID }
        it { subdir.name.should == 'assets' }
        it { subdir.path.should == 'app/assets' }
      end

      context :deep_subdir do
        let(:subdir) { Gitlab::Git::Tree.where(repository, ValidCommit::ID, 'app/views/admin/projects').first }

        it { subdir.should be_kind_of Gitlab::Git::Tree }
        it { subdir.id.should == '4f6bc692b675421f16b023952c049c047c09a502' }
        it { subdir.commit_id.should == ValidCommit::ID }
        it { subdir.name.should == '_form.html.haml' }
        it { subdir.path.should == 'app/views/admin/projects/_form.html.haml' }
      end
    end

    describe :file do
      let(:file) { tree.select(&:file?).first }

      it { file.should be_kind_of Gitlab::Git::Tree }
      it { file.id.should == '87c3f5a1c158686373e3179b503b0a7b7987587b' }
      it { file.commit_id.should == ValidCommit::ID }
      it { file.name.should == '.foreman' }
    end
  end

  context :repo_with_submodules do
    let(:repository) { Gitlab::Git::Repository.new(TEST_SUB_REPO_PATH) }
    let(:tree) { Gitlab::Git::Tree.where(repository, '898ce92b0e0b5ade8a7ef7e3c779dda476b3eef8') }

    it { tree.should be_kind_of Array }
    it { tree.empty?.should be_false }
    it { tree.select(&:dir?).size.should == 0 }
    it { tree.select(&:file?).size.should == 2 }
    it { tree.select(&:submodule?).size.should == 3 }

    describe :submodule do
      let(:submodule) { tree.select(&:submodule?).first }

      it { submodule.should be_kind_of Gitlab::Git::Tree }
      it { submodule.id.should == '68303eddb6982f25e636fa3a4b8842af672da15a' }
      it { submodule.commit_id.should == '898ce92b0e0b5ade8a7ef7e3c779dda476b3eef8' }
      it { submodule.name.should == 'encoding' }
    end
  end
end
