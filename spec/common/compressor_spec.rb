# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2017, Sebastian Staudt

require 'helper'

shared_examples_for 'a compressor' do

  before do
    @io = StringIO.new
    @bz2_compressor = described_class.new @io
  end

  it 'acts like a standard IO' do
    methods = described_class.instance_methods.map &:to_sym
    expect(methods).to include(:write, :close)
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

  after do
    @bz2_compressor.close unless @bz2_compressor.nil?
  end

end
