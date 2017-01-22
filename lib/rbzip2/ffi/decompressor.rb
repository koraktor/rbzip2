# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Brian Lopez
# Copyright (c) 2013-2017, Sebastian Staudt

class RBzip2::FFI::Decompressor

  extend ::FFI::Library

  ffi_lib ::FFI::Platform::LIBC
  attach_function :fopen,
                  [:string, :string],
                  :pointer
  attach_function :fclose,
                  [:pointer],
                  :int

  ffi_lib 'bz2'
  attach_function :BZ2_bzRead,
                  [:pointer, :pointer, :pointer, :int],
                  :int
  attach_function :BZ2_bzReadClose,
                  [:pointer, :pointer],
                  :void
  attach_function :BZ2_bzReadOpen,
                  [:pointer, :pointer, :int, :int, :pointer, :int],
                  :pointer
  attach_function :BZ2_bzBuffToBuffDecompress,
                  [:pointer, :buffer_inout, :pointer, :uint32, :int, :int],
                  :int

  def self.decompress(data, factor = 2, small = 0, verbosity = 0)
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

  def read_file(length)
    error = ::FFI::MemoryPointer.new :uint32
    dst_buf = ::FFI::MemoryPointer.new :char, length

    open_file if @bz_file.nil?

    BZ2_bzRead error, @bz_file, dst_buf, length

    dst_buf.read_bytes length
  end

  def initialize(io)
    @io = io
  end

  def close
    if @io != $stdin
      @io = nil
      @data = nil
    end

    close_file unless @bz_file.nil?
  end

  def close_file
    error = ::FFI::MemoryPointer.new :uint32
    BZ2_bzReadClose error, @bz_file
    fclose @file
  end

  def getc
    read 1
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

  def open_file(verbosity = 0, small = 0)
    raise 'IO not a file' unless @io.is_a? File

    small = 0 if small < 0
    verbosity = 0 if verbosity < 0
    verbosity = 4 if verbosity > 4

    error = ::FFI::MemoryPointer.new :uint32

    @file = fopen @io.path, 'r'
    @bz_file = BZ2_bzReadOpen error, @file, verbosity, small, nil, 0
  end

  def read(length = nil)
    raise 'stream closed' if @io.nil?

    if length.nil?
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
    else
      if @io.is_a? File
        data = read_file length
      else
        raise NotImplementedError
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

  def inspect
    "#<#{self.class}: @io=#{@io.inspect} size=#{size} uncompressed=#{uncompressed}>"
  end

end
