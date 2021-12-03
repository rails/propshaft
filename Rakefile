require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = FileList["test/**/*_test.rb"]
  test.warning = true
end

task default: :test
