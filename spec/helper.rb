# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2017, Sebastian Staudt

require 'rspec/core'
require 'rspec/expectations'

require 'coveralls'
Coveralls.wear!

require 'rbzip2'

include RBzip2

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end

def java?
  defined?(::RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
end

def fixture(file)
  File.new File.join(File.dirname(__FILE__), file)
end
