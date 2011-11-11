# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'rbzip2/constants'

class RBzip2::InputData

  attr_reader :base, :cftab, :get_and_move_to_front_decode_yy, :in_use,
              :limit, :ll8, :min_lens, :perm, :receive_decoding_tables_pos,
              :selector, :selector_mtf, :seq_to_unseq, :temp_char_array_2d,
              :unzftab, :tt

  def initialize(block_size)
    @in_use = Array.new 256, false

    @seq_to_unseq = Array.new 256, 0
    @selector = Array.new RBzip2::MAX_SELECTORS, 0
    @selector_mtf = Array.new RBzip2::MAX_SELECTORS, 0

    @unzftab = Array.new 256, 0

    @base = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @base[i] = Array.new(RBzip2::MAX_ALPHA_SIZE, 0) }
    @limit = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @limit[i] = Array.new(RBzip2::MAX_ALPHA_SIZE, 0) }
    @perm = Array.new RBzip2::N_GROUPS
    RBzip2:: N_GROUPS.times { |i| @perm[i] = Array.new(RBzip2::MAX_ALPHA_SIZE, 0) }
    @min_lens = Array.new RBzip2::N_GROUPS, 0

    @cftab = Array.new 257, 0
    @get_and_move_to_front_decode_yy = Array.new 256
    @temp_char_array_2d = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @temp_char_array_2d[i] = Array.new(RBzip2::MAX_ALPHA_SIZE, 0) }
    @receive_decoding_tables_pos = Array.new RBzip2::N_GROUPS, 0

    @ll8 = Array.new block_size * RBzip2::BASEBLOCKSIZE
  end

  def init_tt(size)
    tt_shadow = @tt

    if tt_shadow.nil? || tt_shadow.size < size
      @tt = tt_shadow = Array.new(size)
    end

    tt_shadow
  end

end
