module SeedHelper
  GITLAB_URL = "https://gitlab.com/gitlab-org/gitlab-git-test.git"

  def ensure_seeds
    if File.exists?(SUPPORT_PATH)
      FileUtils.rm_r(SUPPORT_PATH)
    end

    FileUtils.mkdir_p(SUPPORT_PATH)

    create_bare_seeds
    create_normal_seeds
    create_mutable_seeds
  end

  def create_bare_seeds
    system(git_env, *%W(git clone --bare #{GITLAB_URL}), chdir: SUPPORT_PATH)
  end

  def create_normal_seeds
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_NORMAL_REPO_PATH}))
  end

  def create_mutable_seeds
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_MUTABLE_REPO_PATH}))
    system(git_env, *%w(git branch -t feature origin/feature),
           chdir: TEST_MUTABLE_REPO_PATH)
    system(git_env, *%W(git remote add expendable #{GITLAB_URL}),
           chdir: TEST_MUTABLE_REPO_PATH)
  end

  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    {'GIT_TEMPLATE_DIR' => ''}
  end
end
