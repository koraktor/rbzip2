# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Sebastian Staudt

module RBzip2::Java

  def self.init
    begin
      require 'java'
      include_package 'org.apache.commons.compress.compressors.bzip2'
      BZip2CompressorOutputStream
    rescue LoadError, NameError
      @@available = false
    end
  end

  extend RBzip2::Adapter

  autoload :Compressor,   'rbzip2/java/compressor'
  autoload :Decompressor, 'rbzip2/java/decompressor'

end
