#!/usr/bin/env rake

require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Stately'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :spec do
  desc 'Run unit specs'
  RSpec::Core::RakeTask.new('unit') do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  desc 'Run functional specs'
  RSpec::Core::RakeTask.new('functional') do |t|
    t.pattern = 'spec/functional/**/*_spec.rb'
  end
end

task :console do
  require 'pry'
  require 'stately'
  ARGV.clear
  Pry.start
end

desc 'Run unit and functional specs'
task :spec => ['spec:unit', 'spec:functional']

task :default => :spec
