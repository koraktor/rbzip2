# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2013, Sebastian Staudt

module RBzip2

  autoload :Adapter, 'rbzip2/adapter'
  autoload :FFI,     'rbzip2/ffi'
  autoload :IO,      'rbzip2/io'
  autoload :Ruby,    'rbzip2/ruby'
  autoload :VERSION, 'rbzip2/version'

  def self.default_adapter
    return FFI if FFI.available?
    Ruby
  end

end
