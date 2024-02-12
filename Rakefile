# frozen_string_literal: true

require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'

namespace :test do
  desc 'Run all tests'
  Rake::TestTask.new(:all) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end

  desc 'Run specific test'
  task :run, [:file] do |_task, args|
    file, name = args.file.split(':')

    test_command = "ruby -Ilib:test #{__dir__}/#{file}"
    test_command += " --name /#{name}/" if name

    system(test_command)
  end

  desc 'Run Benchmarks'
  Rake::TestTask.new(:benchmarks) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_bench.rb']
  end
end
