# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2013, Sebastian Staudt

require File.expand_path(File.dirname(__FILE__) + '/lib/rbzip2/version')

Gem::Specification.new do |s|
  s.name        = 'rbzip2'
  s.version     = RBzip2::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ 'Sebastian Staudt' ]
  s.email       = [ 'koraktor@gmail.com' ]
  s.homepage    = 'https://github.com/koraktor/rbzip2'
  s.summary     = 'bzip2 for Ruby'
  s.description = 'Various bzip2 implementations for Ruby.'

  s.files         = Dir['{lib}/**/*.rb', 'LICENSE', 'Rakefile', 'README.md']
  s.test_files    = Dir['{spec}/**/*_spec.rb']
  s.require_paths = [ 'lib' ]
end
