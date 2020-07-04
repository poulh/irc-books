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
  system('sudo gem uninstall irc-books && rm *.gem &&  gem build *.gemspec &&  rake test && sudo gem install *.gem && irc-books')
end

desc 'Run tests'
task default: :install
