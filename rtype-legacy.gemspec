$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rtype/legacy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "rtype-legacy"
  s.version = Rtype::Legacy::VERSION
  s.authors = ["Sputnik Gugja"]
  s.email = ["sputnikgugja@gmail.com"]
  s.homepage = "https://github.com/sputnikgugja/rtype-legacy"
  s.summary = "Rtype for ruby 1.9+"
  s.description = "Rtype for old ruby (1.9+)"
  s.licenses = 'MIT'

  s.test_files = Dir["{test,spec}/**/*"]
    # s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.require_paths = ["lib"] # by default it is ["lib"]

  # s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "rake", "~> 11.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "coveralls"

  s.required_ruby_version = ">= 1.9"

  s.files = Dir["{lib}/**/*", "Rakefile", "Gemfile", "README.md", "LICENSE"]
end
