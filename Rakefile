require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
end

desc "Run tests"
task :default do

  puts "\nIf you want to run tests that submit simple jobs to batch system, " \
    "set the environment variable LIVETEST.\n\n" unless ENV['LIVETEST']

  Rake::Task['test'].invoke
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'osc/machete'
  ARGV.clear
  IRB.start
end
