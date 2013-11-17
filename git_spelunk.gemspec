Gem::Specification.new do |s|
  s.name        = "git_spelunk"
  s.version     = "0.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Osheroff", "Saroj Yadav"]
  s.email       = ["ben@zendesk.com", "saroj@zendesk.com"]
  s.homepage    = "https://github.com/osheroff/git-spelunk"
  s.summary     = "A git tool for exploring history and blame"
  s.description = "git-spelunk is a terminal based exploration tool for git blame and history, based on the notion of moving in history based on file context"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency("grit")

  s.files        = Dir.glob("lib/**/*")
  s.executables  << "git-spelunk"
  s.require_path = 'lib'
end
