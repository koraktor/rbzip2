# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'base64'

require 'helper'

shared_examples_for 'a compressor' do

  before do
    @io = StringIO.new
    @bz2_compressor = described_class.new @io
  end

  it 'acts like a standard IO' do
    methods = described_class.instance_methods.map &:to_sym
    expect(methods).to include(:close, :putc, :puts, :write)
  end

  it 'should be able to compress raw data' do
    txt_file = fixture 'fixtures/test.txt'
    bz2_file  = fixture 'fixtures/test.bz2'
    @bz2_compressor.write txt_file.read
    @bz2_compressor.close

    eq_bz2 = eq bz2_file.read
    eq_bz2.instance_variable_set :@diffable, false
    expect(@io.string).to eq_bz2
  end

  it 'should be able to compress large raw data' do
    txt_file = fixture 'fixtures/big_test.txt'
    suffix = '.' + described_class.name.split('::')[1].downcase
    suffix = '' if suffix == '.ffi'
    bz2_file = fixture "fixtures/big_test#{suffix}.bz2"
    @bz2_compressor.write txt_file.read
    @bz2_compressor.close

    eq_bz2 = eq bz2_file.read
    eq_bz2.instance_variable_set :@diffable, false
    expect(@io.string).to eq_bz2
  end

  it 'should be able to compress a single character' do
    @bz2_compressor.putc 'T'
    @bz2_compressor.putc 'e'
    @bz2_compressor.putc 's'
    @bz2_compressor.putc 't'
    @bz2_compressor.close

    base64_result = Base64.encode64 @io.string

    expect(`echo "#{base64_result}" | base64 -D | bzcat`).to eq('Test')
  end

  it 'should be able to compress a line of text' do
    @bz2_compressor.puts 'Test 1'
    @bz2_compressor.puts 'Test 2'
    @bz2_compressor.close

    base64_result = Base64.encode64 @io.string

    expect(`echo "#{base64_result}" | base64 -D | bzcat`).to eq("Test 1#{$/}Test 2#{$/}")
  end

  after do
    @bz2_compressor.close unless @bz2_compressor.nil?
  end

end
