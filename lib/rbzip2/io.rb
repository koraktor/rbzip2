# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'rbzip2/decompressor'

class RBzip2::IO

  include RBzip2::Decompressor

  def initialize(io)
    @buff = 0
    @bytes_read = 0
    @computed_combined_crc = 0
    @crc = RBzip2::CRC.new
    @current_char = -1
    @io = io
    @live = 0
    @stored_combined_crc = 0
    @su_t_pos = 0
    init
  end

end
