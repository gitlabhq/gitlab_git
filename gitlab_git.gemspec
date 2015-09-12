Gem::Specification.new do |s|
  s.name        = 'gitlab_git'
  s.version     = `cat VERSION`
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = "Gitlab::Git library"
  s.description = "GitLab wrapper around git objects"
  s.authors     = ["Dmitriy Zaporozhets"]
  s.email       = 'dmitriy.zaporozhets@gmail.com'
  s.license     = 'MIT'
  s.files       = `git ls-files lib/`.split("\n") << 'VERSION'
  s.homepage    =
    'http://rubygems.org/gems/gitlab_git'

  s.add_dependency("github-linguist", "~> 4.5.15")
  s.add_dependency("activesupport", "~> 4.0")
  s.add_dependency("rugged", "~> 0.23.0b")
  s.add_dependency("charlock_holmes", "~> 0.7.3")
end
