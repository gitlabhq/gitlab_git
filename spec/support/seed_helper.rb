module SeedHelper
  def ensure_seeds
    unless File.exists?(TEST_REPO_PATH)
      create_seeds
    end
  end

  def create_seeds
    puts 'Prepare seeds'
    FileUtils.mkdir_p(SUPPORT_PATH)
    system(*%W(git clone --bare https://github.com/gitlabhq/testme.git), chdir: SUPPORT_PATH)
  end
end
