Gem::Specification.new do |s|
  s.name        = 'gitlab_git'
  s.version     = `cat VERSION`
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = "Gitlab::Git library"
  s.description = "GitLab wrapper around git objects"
  s.authors     = ["Dmitriy Zaporozhets"]
  s.email       = 'dmitriy.zaporozhets@gmail.com'
  s.license     = 'MIT'
  s.files       = `git ls-files lib/`.split("\n")
  s.homepage    =
    'http://rubygems.org/gems/gitlab_git'

  s.add_dependency("github-linguist", "~> 2.9.4")
  s.add_dependency("gitlab-grit", "~> 2.6.0")
  s.add_dependency("activesupport", "~> 3.2.13")
end
