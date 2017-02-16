# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013-2017, Sebastian Staudt

class RBzip2::Java::Compressor

  def initialize(io)
    @io = RBzip2::Java::BZip2CompressorOutputStream.new io.to_outputstream
  end

  def flush
    @io.flush
  end

  def close
    @io.close
  end

  def putc(int)
    if int.is_a? Numeric
      write int & 0xff
    else
      write int.to_s[0]
    end
  end

  def puts(line)
    write line + $/
  end

  def write(bytes)
    raise 'stream closed' if @io.nil?

    @io.write bytes.to_java_bytes
  end

end
