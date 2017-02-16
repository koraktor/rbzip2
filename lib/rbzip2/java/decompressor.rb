# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013-2017, Sebastian Staudt

class RBzip2::Java::Decompressor

  def initialize(io)
    @io = io
    @is = RBzip2::Java::BZip2CompressorInputStream.new io.to_inputstream
  end

  def close
    @is.close
  end

  def getc
    read(1)[0].chr
  end

  def gets
    line = ''
    loop do
      char = getc
      line += char
      break if char == "\n"
    end
    line
  end

  def read(length = nil)
    if length.nil?
      bytes = Java::byte[0].new
      chunk = Java::byte[1024].new
      begin
        bytes_read = @is.read chunk
        chunk = chunk[0..(bytes_read - 1)] if bytes_read < 1024
        bytes += chunk
      end while bytes_read == 1024
    else
      bytes = Java::byte[length].new
      @is.read bytes
    end

    String.from_java_bytes bytes
  end

  def size
    if @io.is_a? StringIO
      @io.size
    elsif @io.is_a? File
      @io.stat.size
    end
  end

  def uncompressed
    @data = read
    @data.size
  end

  def inspect
    "#<#{self.class}: @io=#{@io.inspect} size=#{size} uncompressed=#{uncompressed}>"
  end

end
