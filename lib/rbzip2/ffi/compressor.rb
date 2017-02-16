# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Brian Lopez
# Copyright (c) 2013-2017, Sebastian Staudt

class RBzip2::FFI::Compressor

  extend ::FFI::Library

  ffi_lib 'bz2'
  attach_function :BZ2_bzBuffToBuffCompress,
                  [:pointer, :buffer_inout, :pointer, :uint32, :int, :int, :int],
                  :int

  def self.compress(data, blksize = RBzip2::FFI::DEFAULT_BLK_SIZE, verbosity = 0, work_factor = 30)
    blksize = 1 if blksize < 1
    blksize = 9 if blksize > 9
    verbosity = 0 if verbosity < 0
    verbosity = 4 if verbosity > 4
    work_factor = 0 if work_factor < 0
    work_factor = 250 if work_factor > 250

    out_len = data.bytesize + (data.bytesize * 0.01) + 600
    dst_buf = ::FFI::MemoryPointer.new :char, out_len
    dst_len = ::FFI::MemoryPointer.new :uint32
    dst_len.write_uint out_len

    src_buf = ::FFI::MemoryPointer.new :char, data.bytesize
    src_buf.put_bytes 0, data

    ret = BZ2_bzBuffToBuffCompress dst_buf, dst_len, src_buf, data.bytesize,
                                   blksize, verbosity, work_factor

    case ret
      when RBzip2::FFI::BZ_OK
        dst_buf.read_bytes dst_len.read_uint
      when RBzip2::FFI::BZ_PARAM_ERROR
        raise ArgumentError, 'One of blksize, verbosity or work_factor is out of range'
      when RBzip2::FFI::BZ_MEM_ERROR
        raise NoMemoryError, 'Out of memory'
      when RBzip2::FFI::BZ_OUTBUFF_FULL
        raise RBzip2::FFI::BufferError, "Output buffer isn't large enough"
      when RBzip2::FFI::BZ_CONFIG_ERROR
        raise RBzip2::FFI::ConfigError, 'libbz2 has been mis-compiled'
      else
        raise RBzip2::FFI::Error, "Unhandled error code: #{ret}"
    end
  end

  def initialize(io)
    @io = io
  end

  def flush
    @io.flush unless @io.nil?
  end

  def close
    flush
    unless @io.nil?
      @io.close
      @io = nil
    end
  end

  def putc(int)
    if int.is_a? Numeric
      write int & 0xff
    else
      write int.to_s[0].chr
    end
  end

  def puts(line)
    write line + $/
  end

  def write(bytes)
    raise 'stream closed' if @io.nil?

    @io.write self.class.compress(bytes, 9)
  end

end
