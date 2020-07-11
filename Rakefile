# frozen_string_literal: true

# require "bundler/gem_tasks"
# require "rspec/core/rake_task"

# RSpec::Core::RakeTask.new(:spec)

# task :default => :spec

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task :install do
  # task code ...
  # Run Rake Test
  # Uninstall old gem versions
  # delete old gem files in dev directory
  # build new gem from gemspec
  # install new gem
  # run irc-books
  tasks = ['rake test', 'sudo gem uninstall irc-books',
           'rm *.gem', 'gem build *.gemspec',
           'sudo gem install *.gem', 'irc-books']
  cmd = tasks.join(' && ')
  system(cmd)
end

desc 'Run tests'
task default: :install
