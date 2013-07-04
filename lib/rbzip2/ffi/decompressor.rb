# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Brian Lopez
# Copyright (c) 2013, Sebastian Staudt

class RBzip2::FFI::Decompressor

  extend ::FFI::Library

  ffi_lib 'bz2'
  attach_function :BZ2_bzBuffToBuffDecompress,
                  [:pointer, :buffer_inout, :pointer, :uint32, :int, :int],
                  :int

  def self.decompress(data, factor = 2, small = 0, verbosity = 0)
    small = 0 if small < 0
    verbosity = 0 if verbosity < 0
    verbosity = 4 if verbosity > 4

    out_len = data.bytesize * factor
    dst_buf = ::FFI::MemoryPointer.new :char, out_len
    dst_len = ::FFI::MemoryPointer.new :uint32
    dst_len.write_uint out_len

    src_buf = ::FFI::MemoryPointer.new :char, data.bytesize
    src_buf.put_bytes 0, data

    ret = BZ2_bzBuffToBuffDecompress dst_buf, dst_len, src_buf, data.bytesize,
                                     small, verbosity

    case ret
      when RBzip2::FFI::BZ_OK
        dst_buf.read_bytes dst_len.read_uint
      when RBzip2::FFI::BZ_PARAM_ERROR
        raise ArgumentError, 'One of sall or verbosity'
      when RBzip2::FFI::BZ_MEM_ERROR
        raise NoMemoryError, 'Out of memory'
      when RBzip2::FFI::BZ_OUTBUFF_FULL
        raise RBzip2::FFI::BufferError, "Output buffer isn't large enough"
      when RBzip2::FFI::BZ_DATA_ERROR, RBzip2::FFI::BZ_DATA_ERROR_MAGIC,
           RBzip2::FFI::BZ_UNEXPECTED_EOF
        raise RBzip2::FFI::CorruptError, 'Compressed data appears to be corrupt or unreadable'
      when RBzip2::FFI::BZ_CONFIG_ERROR
        raise RBzip2::FFI::ConfigError, 'libbz2 has been mis-compiled'
      else
        raise RBzip2::FFI::Error, "Unhandled error code: #{ret}"
    end
  end

  def initialize(io)
    @io = io
  end

  def close
    if @io != $stdin
      @io = nil
      @data = nil
    end
  end

  def read(length = nil)
    raise 'stream closed' if @io.nil?

    factor = 4
    compressed_data = @io.read
    data = nil
    while data.nil?
      begin
        data = self.class.decompress compressed_data, factor
      rescue RBzip2::FFI::BufferError
        factor = factor ** 2
      end
    end

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

end
