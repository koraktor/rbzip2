# This code is free software you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

class RBzip2::Compressor

  include RBzip2::Constants

  def self.assign_codes(code, length, min_len, max_len, alpha_size)
    vec = 0
    min_len.upto(max_len) do |n|
      alpha_size.times do |i|
        if (length[i] & 0xff) == n
          code[i] = vec
          vec += 1
        end
      end
      vec <<= 1
    end
  end

  def self.choose_block_size(input_length)
    input_length > 0 ? [(input_length / 132000) + 1, 9].min : MAX_BLOCK_SIZE
  end

  def self.make_code_lengths(len, freq, data, alpha_size, max_len)
    heap   = data.heap
    weight = data.weight
    parent = data.parent

    weight[0] = 0
    (alpha_size - 1).downto(0) do |i|
      weight[i + 1] = (freq[i] == 0 ? 1 : freq[i]) << 8
    end

    too_long = true
    while too_long
      too_long = false

      n_nodes   = alpha_size
      n_heap    = 0
      heap[0]   = 0
      weight[0] = 0
      parent[0] = -2

      1.upto(alpha_size) do |i|
        parent[i] = -1
        n_heap += 1
        heap[n_heap] = i

        zz = n_heap
        tmp = heap[zz]
        while weight[tmp] < weight[heap[zz >> 1]]
          heap[zz] = heap[zz >> 1]
          zz >>= 1
        end
        heap[zz] = tmp
      end

      while n_heap > 1
        n1 = heap[1]
        heap[1] = heap[n_heap]
        n_heap -= 1

        yy  = 0
        zz  = 1
        tmp = heap[1]

        loop do
          yy = zz << 1

          break if yy > n_heap

          yy += 1 if (yy < n_heap) && (weight[heap[yy + 1]] < weight[heap[yy]])

          break if weight[tmp] < weight[heap[yy]]

          heap[zz] = heap[yy]
          zz = yy
        end

        heap[zz] = tmp

        n2 = heap[1]
        heap[1] = heap[n_heap]
        n_heap -= 1

        yy = 0
        zz = 1
        tmp = heap[1]

        loop do
          yy = zz << 1

          break if yy > n_heap

          yy += 1 if (yy < n_heap) && (weight[heap[yy + 1]] < weight[heap[yy]])

          break if weight[tmp] < weight[heap[yy]]

          heap[zz] = heap[yy]
          zz = yy
        end

        heap[zz] = tmp
        n_nodes += 1
        parent[n1] = parent[n2] = n_nodes

        weight_n1 = weight[n1]
        weight_n2 = weight[n2]
        weight[n_nodes] = ((weight_n1 & 0xffffff00) +
                          (weight_n2 & 0xffffff00)) |
                          (1 + (((weight_n1 & 0x000000ff) >
                          (weight_n2 & 0x000000ff)) ? (weight_n1 & 0x000000ff) :
                          (weight_n2 & 0x000000ff)))

        parent[n_nodes] = -1
        n_heap += 1
        heap[n_heap] = n_nodes

        tmp = 0
        zz = n_heap
        tmp = heap[zz]
        weight_tmp = weight[tmp]
        while weight_tmp < weight[heap[zz >> 1]]
          heap[zz] = heap[zz >> 1]
          zz >>= 1
        end
        heap[zz] = tmp
      end

      1.upto(alpha_size) do |i|
        j = 0
        k = i

        while (parent_k = parent[k]) >= 0
          k = parent_k
          j += 1
        end

        len[i - 1] = j
        too_long = true if j > max_len
      end

      if too_long
        1.upto(alpha_size) do |i|
          j = weight[i] >> 8
          j = 1 + (j >> 1)
          weight[i] = j << 8
        end
      end
    end
  end

  def self.med3(a, b, c)
    (a < b) ? (b < c ? b : a < c ? c : a) : (b > c ? b : a > c ? c : a)
  end

  def self.vswap(fmap, p1, p2, n)
    n += p1
    while p1 < n
      t = fmap[p1]
      fmap[p1] = fmap[p2]
      fmap[p2] = t
      p1 += 1
      p2 += 1
    end
  end

  attr_reader :block_size

  def initialize(io, block_size = MAX_BLOCK_SIZE)
    @allowable_block_size = 0
    @block_size           = block_size
    @buff                 = 0
    @combined_crc         = 0
    @crc                  = RBzip2::CRC.new
    @current_char         = -1
    @io                   = io
    @last                 = 0
    @live                 = 0
    @run_length           = 0

    init
  end

  def block_sort
    @work_limit = WORK_FACTOR * @last
    @work_done = 0
    @block_randomized = false
    @first_attempt = true
    main_sort

    if @first_attempt && @work_done > @work_limit
      randomize_block
      @work_limit = @work_done = 0
      @first_attempt = false
      main_sort
    end

    fmap = @data.fmap
    @orig_ptr = -1
    (@last + 1).times do |i|
      if fmap[i] == 0
        @orig_ptr = i
        break
      end
    end
  end

  def close
    unless @io.nil?
      io_shadow = @io
      finish
      io_shadow.close
    end
  end

  def end_block
    @block_crc = @crc.final_crc
    @combined_crc = (@combined_crc << 1) | (@combined_crc >> 31)
    @combined_crc ^= @block_crc

    return if @last == -1

    block_sort

    put_byte 0x31
    put_byte 0x41
    put_byte 0x59
    put_byte 0x26
    put_byte 0x53
    put_byte 0x59

    put_int @block_crc

    @block_randomized ? w(1, 1) : w(1, 0)

    move_to_front_code_and_send
  end

  def end_compression
    put_byte 0x17
    put_byte 0x72
    put_byte 0x45
    put_byte 0x38
    put_byte 0x50
    put_byte 0x90

    put_int @combined_crc

    finished_with_stream
  end

  def finish
    unless @io.nil?
      begin
        write_run if @run_length > 0
        @current_char = -1
        end_block
        end_compression
      ensure
        @io  = nil
        @data = nil
      end
    end
  end

  def finished_with_stream
    while @live > 0
      @io.write((@buff >> 24).chr)
      @buff <<= 8
      @buff &= 0xffffffff
      @live -= 8
    end
  end

  def flush
    @io.flush unless @io.nil?
  end

  def generate_mtf_values
    last_shadow = @last
    data_shadow = @data
    in_use = data_shadow.in_use
    block = data_shadow.block
    fmap = data_shadow.fmap
    sfmap = data_shadow.sfmap
    mtf_freq = data_shadow.mtf_freq
    unseq_to_seq = data_shadow.unseq_to_seq
    yy = data_shadow.generate_mtf_values_yy

    n_in_use_shadow = 0
    256.times do |i|
      if in_use[i]
        unseq_to_seq[i] = n_in_use_shadow
        n_in_use_shadow += 1
      end
    end
    @n_in_use = n_in_use_shadow

    eob = n_in_use_shadow + 1
    eob.times { |i| mtf_freq[i] }

    n_in_use_shadow.times { |i| yy[i] = i }

    wr = 0
    z_pend = 0

    0.upto(last_shadow) do |i|
      ll_i = unseq_to_seq[block[fmap[i]] & 0xff]
      tmp = yy[0]
      j = 0

      while ll_i != tmp
        j += 1
        tmp2 = tmp
        tmp = yy[j]
        yy[j] = tmp2
      end
      yy[0] = tmp

      if j == 0
        z_pend += 1
      else
        if z_pend > 0
          z_pend -= 1
          loop do
            if (z_pend & 1) == 0
              sfmap[wr] = RUNA
              mtf_freq[RUNA] += 1
            else
              sfmap[wr] = RUNB
              mtf_freq[RUNB] += 1
            end
            wr += 1

            break if z_pend < 2

            z_pend = (z_pend - 2) >> 1
          end
          z_pend = 0
        end
        sfmap[wr] = j + 1
        wr += 1
        mtf_freq[j + 1] += 1
      end
    end

    if z_pend > 0
      z_pend -= 1
      loop do
        if (z_pend & 1) == 0
          sfmap[wr] = RUNA
          mtf_freq[RUNA] += 1
        else
          sfmap[wr] = RUNB
          mtf_freq[RUNB] += 1
        end
        wr += 1

        break if z_pend < 2

        z_pend = (z_pend - 2) >> 1
      end
    end

    sfmap[wr] = eob
    mtf_freq[eob] += 1
    @n_mtf = wr + 1
  end

  def init
    put_byte 0x42
    put_byte 0x5a

    @data = RBzip2::OutputData.new @block_size

    put_byte 0x68
    put_byte 0x30 + @block_size

    @combined_crc = 0
    init_block
  end

  def init_block
    @crc.initialize_crc
    @last = -1

    in_use = @data.in_use
    in_use[0, 256] = [false] * 256

    @allowable_block_size = (@block_size * BASEBLOCKSIZE) - 20
  end

  def main_sort
    data_shadow = @data
    running_order = data_shadow.main_sort_running_order
    copy = data_shadow.main_sort_copy
    big_done = data_shadow.main_sort_big_done
    ftab = data_shadow.ftab
    block = data_shadow.block
    fmap = data_shadow.fmap
    quadrant = data_shadow.quadrant
    last_shadow = @last
    work_limit_shadow = @work_limit
    first_attempt_shadow = @first_attempt

    65537.times { |i| ftab[i] = 0 }

    NUM_OVERSHOOT_BYTES.times do |i|
      block[last_shadow + i + 2] = block[(i % (last_shadow + 1)) + 1]
    end
    (last_shadow + NUM_OVERSHOOT_BYTES).times do |i|
      quadrant[i] = 0
    end
    block[0] = block[last_shadow + 1]

    c1 = block[0] & 0xff
    (last_shadow + 1).times do |i|
      c2 = block[i + 1] & 0xff
      ftab[(c1 << 8) + c2] += 1
      c1 = c2
    end

    1.upto(65536) { |i| ftab[i] += ftab[i - 1] }

    c1 = block[1] & 0xff
    last_shadow.times do |i|
      c2 = block[i + 2] & 0xff
      fmap[ftab[(c1 << 8) + c2] -= 1] = i
      c1 = c2
    end

    fmap[ftab[((block[last_shadow + 1] & 0xff) << 8) + (block[1] & 0xff)] -= 1] = last_shadow

    256.times do |i|
      big_done[i] = false
      running_order[i] = i
    end

    h = 364
    while h != 1
      h /= 3
      h.upto(255) do |i|
        vv = running_order[i]
        a = ftab[(vv + 1) << 8] - ftab[vv << 8]
        b = h - 1
        j = i

        ro = running_order[j - h]
        while ftab[(ro + 1) << 8] - ftab[ro << 8] > a
          running_order[j] = ro
          j -= h
          break if j <= b
          ro = running_order[j - h]
        end

        running_order[j] = vv
      end
    end

    256.times do |i|
      ss = running_order[i]

      256.times do |j|
        sb = (ss << 8) + j
        ftab_sb = ftab[sb]
        if (ftab_sb & SETMASK) != SETMASK
          lo = ftab_sb & CLEARMASK
          hi = (ftab[sb + 1] & CLEARMASK) - 1
          if hi > lo
            main_qsort3 data_shadow, lo, hi, 2
            return if first_attempt_shadow && (@work_done > work_limit_shadow)
          end
          ftab[sb] = ftab_sb | SETMASK
        end
      end

      256.times { |j| copy[j] = ftab[(j << 8) + ss] & CLEARMASK }

      hj = ftab[(ss + 1) << 8] & CLEARMASK
      (ftab[ss << 8] & CLEARMASK).upto(hj - 1) do |j|
        fmap_j = fmap[j]
        c1 = block[fmap_j] & 0xff
        if !big_done[c1]
          fmap[copy[c1]] = (fmap_j == 0) ? last_shadow : (fmap_j - 1)
          copy[c1] += 1
        end
      end

      255.downto(0) { |j| ftab[(j << 8) + ss] |= SETMASK }

      big_done[ss] = true

      if i < 255
        bb_start = ftab[ss << 8] & CLEARMASK
        bb_size = (ftab[(ss + 1) << 8] & CLEARMASK) - bb_start
        shifts = 0

        while (bb_size >> shifts) > 65534
          shifts += 1
        end

        bb_size.times do |j|
          a2update = fmap[bb_start + j]
          q_val = j >> shifts
          quadrant[a2update] = q_val
          if a2update < NUM_OVERSHOOT_BYTES
            quadrant[a2update + last_shadow + 1] = q_val
          end
        end
      end
    end
  end

  def main_qsort3(data_shadow, lo_st, hi_st, d_st)
    stack_ll = data_shadow.stack_ll
    stack_hh = data_shadow.stack_hh
    stack_dd = data_shadow.stack_dd
    fmap     = data_shadow.fmap
    block    = data_shadow.block

    stack_ll[0] = lo_st
    stack_hh[0] = hi_st
    stack_dd[0] = d_st

    sp = 1
    while (sp -= 1) >= 0
      lo = stack_ll[sp]
      hi = stack_hh[sp]
      d  = stack_dd[sp]

      if (hi - lo < SMALL_THRESH) || (d > DEPTH_THRESH)
        return if main_simple_sort data_shadow, lo, hi, d
      else
        d1 = d + 1
        med = self.class.med3(block[fmap[lo] + d1], block[fmap[hi] + d1], block[fmap[(lo + hi) >> 1] + d1]) & 0xff

        un_lo = lo
        un_hi = hi
        lt_lo = lo
        gt_hi = hi

        while true
          while un_lo <= un_hi
            n = (block[fmap[un_lo] + d1] & 0xff) - med
            if n == 0
              temp = fmap[un_lo]
              fmap[un_lo] = fmap[lt_lo]
              fmap[lt_lo] = temp
              un_lo += 1
              lt_lo += 1
            elsif n < 0
              un_lo += 1
            else
              break
            end
          end

          while un_lo <= un_hi
            n = (block[fmap[un_hi] + d1] & 0xff) - med
            if n == 0
              temp = fmap[un_hi]
              fmap[un_hi] = fmap[gt_hi]
              fmap[gt_hi] = temp
              un_hi -= 1
              gt_hi -= 1
            elsif n > 0
              un_hi -= 1
            else
              break
            end
          end

          if un_lo <= un_hi
            temp = fmap[un_lo]
            fmap[un_lo] = fmap[un_hi]
            fmap[un_hi] = temp
            un_lo += 1
            un_hi -= 1
          else
            break
          end
        end

        if gt_hi < lt_lo
          stack_ll[sp] = lo
          stack_hh[sp] = hi
          stack_dd[sp] = d1
          sp += 1
        else
          n = ((lt_lo - lo) < (un_lo - lt_lo)) ? (lt_lo - lo) : (un_lo - lt_lo)
          self.class.vswap fmap, lo, un_lo - n, n
          m = ((hi - gt_hi) < (gt_hi - un_hi)) ? (hi - gt_hi) : (gt_hi - un_hi)
          self.class.vswap fmap, un_lo, hi - m + 1, m

          n = lo + un_lo - lt_lo - 1
          m = hi - (gt_hi - un_hi) + 1

          stack_ll[sp] = lo
          stack_hh[sp] = n
          stack_dd[sp] = d
          sp += 1

          stack_ll[sp] = n + 1
          stack_hh[sp] = m - 1
          stack_dd[sp] = d1
          sp += 1

          stack_ll[sp] = m
          stack_hh[sp] = hi
          stack_dd[sp] = d
          sp += 1
        end
      end
    end
  end

  def main_simple_sort(data_shadow, lo, hi, d)
    big_n = hi - lo + 1
    return @first_attempt && (@work_done > @work_limit) if big_n < 2

    hp = 0
    while INCS[hp] < big_n
      hp += 1
    end

    fmap = data_shadow.fmap
    quadrant = data_shadow.quadrant
    block = data_shadow.block
    last_shadow = @last
    last_plus_1 = last_shadow + 1
    first_attempt_shadow = @first_attempt
    work_limit_shadow = @work_limit
    work_done_shadow = @work_done

    a = nil
    h = nil
    i1 = nil
    i2 = nil
    j = nil
    mj = nil
    once_runned = nil
    vd = nil
    x = nil

    x_loop = lambda do
      while x > 0
        x -= 4

        if block[i1 + 1] == block[i2 + 1]
          if quadrant[i1] == quadrant[i2]
            if block[i1 + 2] == block[i2 + 2]
              if quadrant[i1 + 1] == quadrant[i2 + 1]
                if block[i1 + 3] == block[i2 + 3]
                  if quadrant[i1 + 2] == quadrant[i2 + 2]
                    if block[i1 + 4] == block[i2 + 4]
                      if quadrant[i1 + 3] == quadrant[i2 + 3]
                        i1 -= last_plus_1 if (i1 += 4) >= last_plus_1
                        i2 -= last_plus_1 if (i2 += 4) >= last_plus_1
                        work_done_shadow += 1
                        next
                      elsif quadrant[i1 + 3] > quadrant[i2 + 3]
                        return true
                      else
                        return false
                      end
                    elsif (block[i1 + 4] & 0xff) > (block[i2 + 4] & 0xff)
                      return true
                    else
                      return false
                    end
                  elsif quadrant[i1 + 2] > quadrant[i2 + 2]
                    return true
                  else
                    return false
                  end
                elsif (block[i1 + 3] & 0xff) > (block[i2 + 3] & 0xff)
                  return true
                else
                  return false
                end
              elsif quadrant[i1 + 1] > quadrant[i2 + 1]
                return true
              else
                return false
              end
            elsif (block[i1 + 2] & 0xff) > (block[i2 + 2] & 0xff)
              return true
            else
              return false
            end
          elsif (quadrant[i1] > quadrant[i2])
            return true
          else
            return false
          end
        elsif (block[i1 + 1] & 0xff) > (block[i2 + 1] & 0xff)
          return true
        else
          return false
        end
      end

      true
    end

    hammer_loop = lambda do
      a = 0

      while true do
        if once_runned
          fmap[j] = a
          break if (j -= h) <= mj
        else
          once_runned = true
        end

        a = fmap[j - h]
        i1 = a + d
        i2 = vd

        if block[i1 + 1] == block[i2 + 1]
          if block[i1 + 2] == block[i2 + 2]
            if block[i1 + 3] == block[i2 + 3]
              if block[i1 + 4] == block[i2 + 4]
                if block[i1 + 5] == block[i2 + 5]
                  if block[i1 += 6] == block[i2 += 6]
                    x = last_shadow

                    break unless x_loop.call
                  else
                    if (block[i1] & 0xff) > (block[i2] & 0xff)
                      next
                    else
                      break
                    end
                  end
                elsif (block[i1 + 5] & 0xff) > (block[i2 + 5] & 0xff)
                  next
                else
                  break
                end
              elsif (block[i1 + 4] & 0xff) > (block[i2 + 4] & 0xff)
                next
              else
                break
              end
            elsif (block[i1 + 3] & 0xff) > (block[i2 + 3] & 0xff)
              next
            else
              break
            end
          elsif (block[i1 + 2] & 0xff) > (block[i2 + 2] & 0xff)
            next
          else
            break
          end
        elsif (block[i1 + 1] & 0xff) > (block[i2 + 1] & 0xff)
          next
        else
          break
        end
      end
    end

    while (hp -= 1) >= 0
      h = INCS[hp]
      mj = lo + h - 1

      i = lo + h
      while i <= hi
        k = 3
        while i <= hi && (k -= 1) >= 0
          v = fmap[i]
          vd = v + d
          j = i

          once_runned = false

          hammer_loop.call

          fmap[j] = v

          i += 1
        end
      end

      break if first_attempt_shadow && i <= hi && work_done_shadow > work_limit_shadow
    end

    @work_done = work_done_shadow

    first_attempt_shadow && (work_done_shadow > work_limit_shadow)
  end

  def move_to_front_code_and_send
    w 24, @orig_ptr
    generate_mtf_values
    send_mtf_values
  end

  def put_byte(c)
    c = c[0].to_i if c.is_a? String
    w 8, c
  end

  def put_int(u)
    w 8, (u >> 24) & 0xff
    w 8, (u >> 16) & 0xff
    w 8, (u >> 8) & 0xff
    w 8, u & 0xff
  end

  def randomize_block
    in_use      = @data.in_use
    block       = @data.block
    last_shadow = @last

    256.times { |i| in_use[i] = false }

    r_n_to_go = 0
    r_t_pos = 0
    j = 1
    i = 0
    while i <= last_shadow
      i = j

      if r_n_to_go == 0
        r_n_to_go = RNUMS[r_t_pos]
        r_t_pos = 0 if (r_t_pos += 1) == 512
      end

      r_n_to_go -= 1
      block[j] ^= r_n_to_go == 1 ? 1 : 0

      in_use[block[j] & 0xff] = true

      j += 1
    end

    @block_randomized = true
  end

  def send_mtf_values
    len = @data.send_mtf_values_len
    alpha_size = @n_in_use + 2

    N_GROUPS.times do |t|
      len_t = len[t]
      alpha_size.times { |v| len_t[v] = GREATER_ICOST }
    end

    n_groups = (@n_mtf < 200) ? 2 : (@n_mtf < 600) ? 3 : (@n_mtf < 1200) ? 4 :
               (@n_mtf < 2400) ? 5 : 6

    send_mtf_values0 n_groups, alpha_size
    n_selectors = send_mtf_values1 n_groups, alpha_size
    send_mtf_values2 n_groups, n_selectors
    send_mtf_values3 n_groups, alpha_size
    send_mtf_values4
    send_mtf_values5 n_groups, n_selectors
    send_mtf_values6 n_groups, alpha_size
    send_mtf_values7
  end

  def send_mtf_values0(n_groups, alpha_size)
    len = @data.send_mtf_values_len
    mtf_freq = @data.mtf_freq

    rem_f = @n_mtf
    gs = 0

    n_groups.downto(1) do |n_part|
      t_freq = rem_f / n_part
      ge = gs - 1
      a_freq = 0

      a = alpha_size - 1
      while a_freq < t_freq && ge < a
        ge += 1
        a_freq += mtf_freq[ge]
      end

      if ge > gs && n_part != n_groups && n_part != 1 &&
         ((n_groups - n_part) & 1) != 0
        ge -= 1
        a_freq -= mtf_freq[ge]
      end

      len_np = len[n_part - 1]
      (alpha_size - 1).downto(0) do |v|
        if v >= gs && v <= ge
          len_np[v] = LESSER_ICOST
        else
          len_np[v] = GREATER_ICOST
        end
      end

      gs = ge +1
      rem_f -= a_freq
    end
  end

  def send_mtf_values1(n_groups, alpha_size)
    data_shadow = @data
    rfreq = data_shadow.send_mtf_values_rfreq
    fave = data_shadow.send_mtf_values_fave
    cost = data_shadow.send_mtf_values_cost
    sfmap = data_shadow.sfmap
    selector = data_shadow.selector
    len = data_shadow.send_mtf_values_len
    len_0 = len[0]
    len_1 = len[1]
    len_2 = len[2]
    len_3 = len[3]
    len_4 = len[4]
    len_5 = len[5]
    n_mtf_shadow = @n_mtf
    n_selectors = 0

    N_ITERS.times do
      (n_groups - 1).downto(0) do |t|
        fave[t] = 0
        rfreqt = rfreq[t]
        (alpha_size - 1).downto(0) { |i| rfreqt[i] = 0 }
      end

      n_selectors = 0

      gs = 0
      while gs < @n_mtf
        ge = [gs + G_SIZE - 1, n_mtf_shadow - 1].min

        if n_groups == N_GROUPS
          cost0 = 0
          cost1 = 0
          cost2 = 0
          cost3 = 0
          cost4 = 0
          cost5 = 0

          gs.upto(ge) do |i|
            icv = sfmap[i]
            cost0 += len_0[icv] & 0xff
            cost1 += len_1[icv] & 0xff
            cost2 += len_2[icv] & 0xff
            cost3 += len_3[icv] & 0xff
            cost4 += len_4[icv] & 0xff
            cost5 += len_5[icv] & 0xff
          end

          cost[0] = cost0
          cost[1] = cost1
          cost[2] = cost2
          cost[3] = cost3
          cost[4] = cost4
          cost[5] = cost5
        else
          (n_groups - 1).downto(0) { |t| cost[t] = 0 }

          gs.upto(ge) do |i|
            icv = sfmap[i]
            (n_groups - 1).downto(0) { |t| cost[t] += len[t][icv] & 0xff }
          end
        end

        bt = -1
        bc = 999999999
        (n_groups - 1).downto(0) do |t|
          cost_t = cost[t]
          if cost_t < bc
            bc = cost_t
            bt = t
          end
        end

        fave[bt] += 1
        selector[n_selectors] = bt
        n_selectors += 1

        rfreq_bt = rfreq[bt]
        gs.upto(ge) { |i| rfreq_bt[sfmap[i]] += 1 }

        gs = ge + 1
      end

      n_groups.times do |t|
        self.class.make_code_lengths len[t], rfreq[t], @data, alpha_size, 20
      end
    end

    n_selectors
  end

  def send_mtf_values2(n_groups, n_selectors)
    data_shadow = @data
    pos = data_shadow.send_mtf_values2_pos

    n_groups.times { |i| pos[i] = i }

    n_selectors.times do |i|
      ll_i = data_shadow.selector[i]
      tmp = pos[0]
      j = 0

      while ll_i != tmp
        j += 1
        tmp2 = tmp
        tmp = pos[j]
        pos[j] = tmp2
      end

      pos[0] = tmp
      data_shadow.selector_mtf[i] = j
    end
  end

  def send_mtf_values3(n_groups, alpha_size)
    code = @data.send_mtf_values_code
    len = @data.send_mtf_values_len

    n_groups.times do |t|
      min_len = 32
      max_len = 0
      len_t = len[t]
      (alpha_size - 1).downto(0) do |i|
        l = len_t[i] & 0xff
        max_len = l if l > max_len
        min_len = l if l < min_len
      end

      self.class.assign_codes code[t], len[t], min_len, max_len, alpha_size
    end
  end

  def send_mtf_values4
    in_use = @data.in_use
    in_use_16 = @data.send_mtf_values4_in_use_16

    15.downto(0) do |i|
      in_use_16[i] = false
      i16 = i * 16
      15.downto(0) do |j|
        in_use_16[i] = true if in_use[i16 + j]
      end
    end

    16.times { |i| w 1, (in_use_16[i] ? 1 : 0) }

    io_shadow   = @io
    live_shadow = @live
    buff_shadow = @buff

    16.times do |i|
      if in_use_16[i]
        i16 = i * 16
        16.times do |j|
          while live_shadow >= 8
            io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
            buff_shadow <<= 8
            buff_shadow &= 0xffffffff
            live_shadow -= 8
          end
          buff_shadow |= 1 << (32 - live_shadow - 1) if in_use[i16 + j]
          live_shadow += 1
        end
      end
    end

    @buff = buff_shadow
    @live = live_shadow
  end

  def send_mtf_values5(n_groups, n_selectors)
    w 3, n_groups
    w 15, n_selectors

    io_shadow   = @io
    selector_mtf = @data.selector_mtf

    live_shadow = @live
    buff_shadow = @buff

    n_selectors.times do |i|
      hj = selector_mtf[i] & 0xff
      hj.times do
        while live_shadow >= 8
          io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
          buff_shadow <<= 8
          buff_shadow &= 0xffffffff
          live_shadow -= 8
        end
        buff_shadow |= 1 << (32 - live_shadow - 1)
        live_shadow += 1
      end

      while live_shadow >= 8
        io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
        buff_shadow <<= 8
        buff_shadow &= 0xffffffff
        live_shadow -= 8
      end
      live_shadow += 1
    end

    @buff = buff_shadow
    @live = live_shadow
  end

  def send_mtf_values6(n_groups, alpha_size)
    len = @data.send_mtf_values_len
    io_shadow = @io

    live_shadow = @live
    buff_shadow = @buff

    n_groups.times do |t|
      len_t = len[t]
      curr = len_t[0] & 0xff

      while live_shadow >= 8
        io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
        buff_shadow <<= 8
        buff_shadow &= 0xffffffff
        live_shadow -= 8
      end
      buff_shadow |= curr << (32 - live_shadow - 5)
      live_shadow += 5

      alpha_size.times do |i|
        lti = len_t[i] & 0xff
        while curr < lti
          while live_shadow >= 8
            io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
            buff_shadow <<= 8
            buff_shadow &= 0xffffffff
            live_shadow -= 8
          end
          buff_shadow |= 2 << (32 - live_shadow - 2)
          live_shadow += 2

          curr += 1
        end

        while curr > lti
          while live_shadow >= 8
            io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
            buff_shadow <<= 8
            buff_shadow &= 0xffffffff
            live_shadow -= 8
          end
          buff_shadow |= 3 << (32 - live_shadow - 2)
          live_shadow += 2

          curr -= 1
        end

        while live_shadow >= 8
          io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
          buff_shadow <<= 8
          buff_shadow &= 0xffffffff
          live_shadow -= 8
        end
        live_shadow += 1
      end
    end

    @buff = buff_shadow
    @live = live_shadow
  end

  def send_mtf_values7
    data_shadow = @data
    len = data_shadow.send_mtf_values_len
    code = data_shadow.send_mtf_values_code
    io_shadow = @io
    selector = data_shadow.selector
    sfmap = data_shadow.sfmap
    n_mtf_shadow = @n_mtf

    sel_ctr = 0

    live_shadow = @live
    buff_shadow = @buff

    gs = 0
    while gs < n_mtf_shadow
      ge = [gs + G_SIZE - 1, n_mtf_shadow - 1].min
      selector_sel_ctr = selector[sel_ctr] & 0xff
      code_sel_ctr = code[selector_sel_ctr]
      len_sel_ctr = len[selector_sel_ctr]

      while gs <= ge
        sfmap_i = sfmap[gs]

        while live_shadow >= 8
          io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
          buff_shadow <<= 8
          buff_shadow &= 0xffffffff
          live_shadow -= 8
        end
        n = len_sel_ctr[sfmap_i] & 0xff
        buff_shadow |= code_sel_ctr[sfmap_i] << (32 - live_shadow - n)
        live_shadow += n

        gs += 1
      end

      gs = ge + 1
      sel_ctr += 1
    end

    @buff = buff_shadow
    @live = live_shadow
  end

  def w(n, v)
    io_shadow = @io
    live_shadow = @live
    buff_shadow = @buff

    while live_shadow >= 8
      io_shadow.write(((buff_shadow >> 24) & 0xffffffff).chr)
      buff_shadow <<= 8
      buff_shadow &= 0xffffffff
      live_shadow -= 8
    end

    @buff = buff_shadow | (v << (32 - live_shadow - n))
    @live = live_shadow + n
  end

  def write(bytes)
    raise 'stream closed' if @io.nil?

    bytes.each_byte { |b| write0 b }
  end

  def write0(b)
    if @current_char != -1
      b &= 0xff
      if @current_char == b
        @run_length += 1
        if @run_length > 254
          write_run
          @current_char = -1
          @run_length = 0
        end
      else
        write_run
        @run_length = 1
        @current_char = b
      end
    else
      @current_char = b & 0xff
      @run_length += 1
    end
  end

  def write_run
    last_shadow = @last

    if last_shadow < @allowable_block_size
      current_char_shadow = @current_char
      data_shadow = @data
      data_shadow.in_use[current_char_shadow] = true
      ch = current_char_shadow

      run_length_shadow = @run_length
      @crc.update_crc current_char_shadow, run_length_shadow

      case run_length_shadow
        when 1
          data_shadow.block[last_shadow + 2] = ch
          @last = last_shadow + 1

        when 2
          data_shadow.block[last_shadow + 2] = ch
          data_shadow.block[last_shadow + 3] = ch
          @last = last_shadow + 2

        when 3
          block = data_shadow.block
          block[last_shadow + 2] = ch
          block[last_shadow + 3] = ch
          block[last_shadow + 4] = ch
          @last = last_shadow + 3

        else
          run_length_shadow -= 4
          data_shadow.in_use[run_length_shadow] = true
          block = data_shadow.block
          block[last_shadow + 2] = ch
          block[last_shadow + 3] = ch
          block[last_shadow + 4] = ch
          block[last_shadow + 5] = ch
          block[last_shadow + 6] = run_length_shadow
          @last = last_shadow + 5
      end
    else
      end_block
      init_block
      write_run
    end
  end

end
