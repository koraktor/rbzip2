# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Sebastian Staudt

module RBzip2::Ruby

  extend RBzip2::Adapter

  autoload :CRC,          'rbzip2/ruby/crc'
  autoload :Compressor,   'rbzip2/ruby/compressor'
  autoload :Constants,    'rbzip2/ruby/constants'
  autoload :Decompressor, 'rbzip2/ruby/decompressor'
  autoload :IO,           'rbzip2/ruby/io'
  autoload :InputData,    'rbzip2/ruby/input_data'
  autoload :OutputData,   'rbzip2/ruby/output_data'

end
