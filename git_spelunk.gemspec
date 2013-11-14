Gem::Specification.new do |s|
  s.name        = "git_spelunk"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Osheroff", "Saroj Yadav"]
  s.email       = ["ben@zendesk.com", "saroj@zendesk.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency("grit")
  s.add_runtime_dependency("debugger")

  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end
