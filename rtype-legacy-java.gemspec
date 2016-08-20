$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rtype/legacy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
	s.name = "rtype-legacy-java"
	s.version = Rtype::Legacy::VERSION
	s.authors = ["Sputnik Gugja"]
	s.email = ["sputnikgugja@gmail.com"]
	s.homepage = "https://github.com/sputnikgugja/rtype"
	s.summary = "Java extension for rtype-legacy"
	s.description = "Java extension for rtype-legacy"
	s.licenses = 'MIT'

	s.test_files = Dir["{test,spec}/**/*"]
	s.require_paths = ["ext"] # by default it is ["lib"]

	s.platform = "java"

	s.add_development_dependency "rake", "~> 11.0"
	s.add_development_dependency "rspec"
	s.add_development_dependency "coveralls"

	s.required_ruby_version = ">= 1.9"

	s.files = Dir["benchmark/*", "Rakefile", "Gemfile", "README.md", "LICENSE", 'ext/rtype/legacy/*.jar']
end
