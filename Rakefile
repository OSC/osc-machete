require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
end

desc "Run tests"
task :default => :test
