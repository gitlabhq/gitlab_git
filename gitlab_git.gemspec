Gem::Specification.new do |s|
  s.name        = 'gitlab_git'
  s.version     = '1.2.0'
  s.date        = '2013-04-29'
  s.summary     = "Gitlab::Git library"
  s.description = "GitLab wrapper around git objects"
  s.authors     = ["Dmitriy Zaporozhets"]
  s.email       = 'dmitriy.zaporozhets@gmail.com'
  s.license     = 'MIT'
  s.files       = `git ls-files lib/`.split("\n")
  s.homepage    =
    'http://rubygems.org/gems/gitlab_git'

  s.add_dependency("github-linguist", "~> 2.3.4")
  s.add_dependency("gitlab-grit", "~> 2.5.1")
  s.add_dependency("activesupport", "~> 3.2.13")
end
