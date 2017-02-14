# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2017, Sebastian Staudt

class RBzip2::IO

  def initialize(io)
    @io           = io
    @compressor   = RBzip2.default_adapter::Compressor.new io
    @decompressor = RBzip2.default_adapter::Decompressor.new io
  end

  def close
    @compressor.close
    @decompressor.close
  end

  def getc
    @decompressor.getc
  end

  def gets
    @decompressor.gets
  end

  def putc(int)
    @compressor.putc int
  end

  def puts(line)
    @compressor.puts line
  end

  def read
    @decompressor.read
  end

  def write(data)
    @compressor.write data
  end

end
