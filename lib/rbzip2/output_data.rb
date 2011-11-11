# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'rbzip2/constants'

class RBzip2::OutputData

  attr_reader :block, :ftab, :fmap, :generate_mtf_values_yy, :heap, :in_use,
              :main_sort_big_done, :main_sort_copy, :main_sort_running_order,
              :mtf_freq, :parent, :quadrant, :selector, :selector_mtf,
              :send_mtf_values_code, :send_mtf_values_cost,
              :send_mtf_values_fave, :send_mtf_values_len,
              :send_mtf_values_rfreq, :send_mtf_values2_pos,
              :send_mtf_values4_in_use_16, :sfmap, :stack_dd, :stack_hh,
              :stack_ll, :unseq_to_seq, :weight

  def initialize(block_size)
    n = block_size * RBzip2::BASEBLOCKSIZE
    @block        = Array.new n + 1 + RBzip2::NUM_OVERSHOOT_BYTES, 0
    @fmap         = Array.new n, 0
    @selector     = Array.new RBzip2::MAX_SELECTORS
    @selector_mtf = Array.new RBzip2::MAX_SELECTORS
    @sfmap        = Array.new 2 * n
    @quadrant     = @sfmap

    @in_use       = Array.new 256
    @mtf_freq     = Array.new RBzip2::MAX_ALPHA_SIZE, 0
    @unseq_to_seq = Array.new 256

    @generate_mtf_values_yy = Array.new 256
    @send_mtf_values_code   = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @send_mtf_values_code[i] = Array.new RBzip2::MAX_ALPHA_SIZE }
    @send_mtf_values_cost   = Array.new RBzip2::N_GROUPS
    @send_mtf_values_fave   = Array.new RBzip2::N_GROUPS
    @send_mtf_values_len    = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @send_mtf_values_len[i] = Array.new RBzip2::MAX_ALPHA_SIZE }
    @send_mtf_values_rfreq  = Array.new RBzip2::N_GROUPS
    RBzip2::N_GROUPS.times { |i| @send_mtf_values_rfreq[i] = Array.new RBzip2::MAX_ALPHA_SIZE, 0 }
    @send_mtf_values2_pos   = Array.new RBzip2::N_GROUPS
    @send_mtf_values4_in_use_16 = Array.new 16

    @stack_dd = Array.new RBzip2::QSORT_STACK_SIZE
    @stack_hh = Array.new RBzip2::QSORT_STACK_SIZE
    @stack_ll = Array.new RBzip2::QSORT_STACK_SIZE

    @main_sort_big_done      = Array.new 256
    @main_sort_copy          = Array.new 256
    @main_sort_running_order = Array.new 256

    @heap   = Array.new RBzip2::MAX_ALPHA_SIZE + 2
    @parent = Array.new RBzip2::MAX_ALPHA_SIZE + 2
    @weight = Array.new RBzip2::MAX_ALPHA_SIZE + 2

    @ftab = Array.new 65537
  end

end
