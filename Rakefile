# -*- encoding: utf-8 -*-

# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'rspec/core/rake_task'
require 'rubygems/package_task'

task :default => :spec

spec = Gem::Specification.load 'rbzip2.gemspec'
Gem::PackageTask.new(spec) do |pkg|
end

RSpec::Core::RakeTask.new('spec') do |t|
end

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |yardoc|
    yardoc.name    = 'doc'
    yardoc.files   = [ 'lib/**/*.rb', 'LICENSE', 'README.md' ]
    yardoc.options = [ '--private', '--title', 'RBzip2 — API Documentation' ]
  end
rescue LoadError
  desc 'Generate YARD Documentation (not available)'
  task :doc do
    $stderr.puts 'You need YARD to build the documentation. Install it using `gem install yard`.'
  end
end

desc 'Clean documentation and package directories'
task :clean do
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'pkg'
end
