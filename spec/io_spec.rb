# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'helper'

describe RBzip2::IO do

  before do
    @txt_file = File.new File.join(File.dirname(__FILE__), 'fixtures/test.txt')
    bz2_file  = File.new File.join(File.dirname(__FILE__), 'fixtures/test.bz2')
    @bz2_io   = RBzip2::IO.new bz2_file
  end

  it 'allows decompressing data' do
    RBzip2::IO.should include(Decompressor)
  end

  it 'acts like a standard IO' do
    methods = RBzip2::IO.instance_methods.map { |m| m.to_sym }
    methods.should include(:read, :close)
  end

  it 'knows its size' do
    @bz2_io.size.should be(375)
  end

  it 'knows the size of the uncompressed data' do
    @bz2_io.uncompressed.should be(704)
  end

  it 'should be able to decompress compressed data' do
    @bz2_io.read.should eq(@txt_file.read)
  end

end
