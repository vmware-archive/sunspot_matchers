require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
desc "Run all specs"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Runs the CI build"
task :cruise do
  Rake::Task["spec"].execute
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end