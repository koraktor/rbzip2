# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'helper'

shared_examples_for 'a decompressor' do

  it 'acts like a standard IO' do
    methods = described_class.instance_methods.map { |m| m.to_sym }
    methods.should include(:close, :read)
  end

  it 'knows its size' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    bz2_decompressor.size.should == 375
  end

  it 'knows the size of the uncompressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    bz2_decompressor.uncompressed.should == 704
  end

  it 'should be able to decompress compressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file
    txt_file = fixture 'fixtures/test.txt'

    bz2_decompressor.read.should eq(txt_file.read)
  end

  it 'should be able to decompress large compressed data' do
    txt_file = fixture 'fixtures/big_test.txt'
    bz2_file = fixture 'fixtures/big_test.bz2'
    bz2_decompressor = described_class.new bz2_file

    bz2_decompressor.read.should eq(txt_file.read)
  end

end
