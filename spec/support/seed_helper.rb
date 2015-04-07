module SeedHelper
  GITHUB_URL = "https://gitlab.com/gitlab-org/gitlab-git-test.git"

  def ensure_seeds
    unless File.exists?(TEST_REPO_PATH)
      create_bare_seeds
    end
    create_normal_seeds unless File.exists?(TEST_NORMAL_REPO_PATH)
    create_mutable_seeds unless File.exists?(TEST_MUTABLE_REPO_PATH)
  end

  def create_bare_seeds
    FileUtils.mkdir_p(SUPPORT_PATH)
    system(git_env, *%W(git clone --bare #{GITHUB_URL}), chdir: SUPPORT_PATH)
  end

  def create_normal_seeds
    FileUtils.mkdir_p(SUPPORT_PATH)
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_NORMAL_REPO_PATH}))
  end

  def create_mutable_seeds
    FileUtils.mkdir_p(SUPPORT_PATH)
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_MUTABLE_REPO_PATH}))
    system(git_env, *%w(git branch -t feature origin/feature),
           chdir: TEST_MUTABLE_REPO_PATH)
    system(git_env, *%W(git remote add expendable #{GITHUB_URL}),
           chdir: TEST_MUTABLE_REPO_PATH)
  end

  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    {'GIT_TEMPLATE_DIR' => ''}
  end
end
