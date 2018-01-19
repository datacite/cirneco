require "date"
require File.expand_path("../lib/cirneco/version", __FILE__)

Gem::Specification.new do |s|
  s.authors       = "Martin Fenner"
  s.email         = "mfenner@datacite.org"
  s.name          = "cirneco"
  s.homepage      = "https://github.com/datacite/cirneco"
  s.summary       = "Ruby client library for the DataCite MDS"
  s.date          = Date.today
  s.description   = "Ruby client library for the DataCite Metadata Store (MDS) API."
  s.require_paths = ["lib"]
  s.version       = Cirneco::VERSION
  s.extra_rdoc_files = ["README.md"]
  s.license       = 'MIT'

  # Declary dependencies here, rather than in the Gemfile
  s.add_dependency 'maremma', '~> 3.5', '>= 3.5.7'
  s.add_dependency 'bergamasco', '~> 0.3'
  s.add_dependency 'bolognese', '~> 0.9'
  s.add_dependency 'base32-url', '~> 0.3'
  s.add_dependency 'nokogiri', '~> 1.8.1'
  s.add_dependency 'builder', '~> 3.2', '>= 3.2.2'
  s.add_dependency 'activesupport', '>= 4.2.5', '< 6'
  s.add_dependency 'dotenv', '~> 2.1', '>= 2.1.1'
  s.add_dependency 'thor', '~> 0.19'
  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rspec-xsd', '~> 0.1.0'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rack-test', '~> 0'
  s.add_development_dependency 'vcr', '~> 3.0', '>= 3.0.3'
  s.add_development_dependency 'webmock', '~> 3.0', '>= 3.0.1'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 1.0', '>= 1.0.0'
  s.add_development_dependency 'simplecov', '~> 0.14.1'

  s.require_paths = ["lib"]
  s.files       = `git ls-files`.split($/)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = ["cirneco"]
end
