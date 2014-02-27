module SeedHelper
  def ensure_seeds
    unless File.exists?(TEST_REPO_PATH)
      create_seeds
    end
  end

  def create_seeds
    puts 'Prepare seeds'
    FileUtils.cd(SUPPORT_PATH) do
      `git clone --bare https://github.com/gitlabhq/testme.git`
    end
  end
end
