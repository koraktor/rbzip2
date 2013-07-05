# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Sebastian Staudt

class RBzip2::Java::Decompressor

  if RBzip2::Java.available?
    import org.apache.commons.compress.compressors.bzip2.BZip2CompressorInputStream
  end

  def initialize(io)
    @io = io
  end

  def close
    if @io != $stdin
      @io = nil
    end
  end

  def read(length = nil)
    raise 'stream closed' if @io.nil?

    is = BZip2CompressorInputStream.new @io.to_inputstream

    if length.nil?
      bytes = Java::byte[0].new
      begin
        chunk = Java::byte[1024].new
        bytes_read = is.read chunk
        chunk = chunk[0..(bytes_read - 1)] if bytes_read < 1024
        bytes += chunk
      end while bytes_read == 1024
      data = String.from_java_bytes bytes
    else
      data = Java::byte[length].new
      is.read data
    end

    is.close

    data
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
