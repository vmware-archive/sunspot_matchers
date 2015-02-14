# -*- encoding: utf-8 -*-
require File.expand_path("../lib/sunspot_matchers/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "sunspot_matchers"
  s.version     = SunspotMatchers::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joseph Palermo"]
  s.email       = []
  s.homepage    = "https://github.com/pivotal/sunspot_matchers"
  s.summary     = "RSpec matchers and Test::Unit assertions for testing Sunspot"
  s.description = "These matchers and assertions allow you to test what is happening inside the Sunspot Search DSL blocks"
  s.license     = "MIT"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "sunspot", "~> 2.1.1"
  s.add_development_dependency "rake"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
