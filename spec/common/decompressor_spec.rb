# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'helper'

shared_examples_for 'a decompressor' do

  it 'acts like a standard IO' do
    methods = described_class.instance_methods.map { |m| m.to_sym }
    expect(methods).to include(:close, :getc, :gets, :read)
  end

  it 'knows its size' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    expect(bz2_decompressor.size).to eq(375)
  end

  it 'knows the size of the uncompressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    expect(bz2_decompressor.uncompressed).to eq(704)
  end

  it 'should be able to decompress compressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file
    txt_file = fixture 'fixtures/test.txt'

    expect(bz2_decompressor.read).to eq(txt_file.read)
  end

  it 'should be able to decompress large compressed data' do
    txt_file = fixture 'fixtures/big_test.txt'
    bz2_file = fixture 'fixtures/big_test.bz2'
    bz2_decompressor = described_class.new bz2_file

    expect(bz2_decompressor.read).to eq(txt_file.read)
  end

  it 'should be able to decompress a single character from compressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    expect(bz2_decompressor.getc).to eq('T')
    expect(bz2_decompressor.getc).to eq('h')
    expect(bz2_decompressor.getc).to eq('i')
    expect(bz2_decompressor.getc).to eq('s')
    expect(bz2_decompressor.getc).to eq(' ')
  end

  it 'should be able to decompress a single line from compressed data' do
    bz2_file = fixture 'fixtures/test.bz2'
    bz2_decompressor = described_class.new bz2_file

    expect(bz2_decompressor.gets).to eq("This is a test fixture for RBzip2.\n")
  end

end
