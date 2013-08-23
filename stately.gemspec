$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'stately/version'

Gem::Specification.new do |s|
  s.name        = 'stately'
  s.version     = Stately::VERSION
  s.authors     = ['Ryan Twomey']
  s.email       = ['rtwomey@gmail.com']
  s.homepage    = 'http://github.com/rtwomey/stately'
  s.summary     = 'A simple, elegant state machine for Ruby'
  s.description = 'Add an elegant state machine to your ruby objects with a simple DSL'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")

  s.add_development_dependency 'redcarpet', '~> 2.2.2'
  s.add_development_dependency 'rspec', '~> 2.0'
  s.add_development_dependency 'yard', '~> 0.8.3'

  s.required_ruby_version = Gem::Requirement.new('>= 1.8.7')
  s.require_paths = ['lib']
end
