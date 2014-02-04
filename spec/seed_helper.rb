module SeedHelper
  def ensure_seeds
    unless File.exists?(TEST_REPO_PATH) && File.exists?(TEST_SUB_REPO_PATH)
      create_seeds
    end
  end

  def create_seeds
    puts 'Prepare seeds'
    FileUtils.cd(SUPPORT_PATH) do
      %w(gitlabhq submodules).each do |repo_name|
        `rm -rf #{repo_name}.git`
        `tar -xf #{repo_name}.tar.gz`
      end
    end
  end
end
