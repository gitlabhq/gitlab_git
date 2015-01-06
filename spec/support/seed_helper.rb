module SeedHelper
  def ensure_seeds
    unless File.exists?(TEST_REPO_PATH)
      create_seeds
    end
  end

  def create_seeds
    puts 'Prepare seeds'
    FileUtils.mkdir_p(SUPPORT_PATH)
    system(*%W(git clone --bare https://gitlab.com/gitlab-org/gitlab-git-test.git #{TEST_REPO_PATH}), chdir: SUPPORT_PATH)
    File.open(File.join(TEST_REPO_PATH, 'refs/heads/master'), 'w') { |f| f.puts SeedRepo::LastCommit::ID }
    IO.popen(%W(git tag), chdir: TEST_REPO_PATH).read.each_line do |tag|
      tag.chomp!
      unless SeedRepo::Repo::TAGS.include?(tag)
        system(*%W(git tag -d -- #{tag}), chdir: TEST_REPO_PATH)
      end
    end
  end
end
