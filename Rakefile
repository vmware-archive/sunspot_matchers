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