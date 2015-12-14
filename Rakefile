require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
end

desc "Run tests"
task :default => :test

task :console do
  require 'irb'
  require 'irb/completion'
  require 'osc/machete'
  ARGV.clear
  IRB.start
end
