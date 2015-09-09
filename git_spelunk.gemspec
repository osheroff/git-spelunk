$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "git_spelunk/version"

Gem::Specification.new do |s|
  s.name        = "git_spelunk"
  s.version     = GitSpelunk::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Osheroff", "Saroj Yadav"]
  s.email       = ["ben@zendesk.com", "saroj@zendesk.com"]
  s.homepage    = "https://github.com/osheroff/git-spelunk"
  s.summary     = "A git tool for exploring history and blame"
  s.description = "git-spelunk is a terminal based exploration tool for git blame and history, based on the notion of moving in history based on file context"

  s.add_runtime_dependency("grit")
  s.add_runtime_dependency("dispel")
  s.add_runtime_dependency("curses")

  s.files = `git ls-files lib bin MIT-LICENSE.txt`.split("\n")
  s.license = "MIT"
  s.executables  << "git-spelunk"
end
