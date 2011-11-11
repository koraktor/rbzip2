# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'helper'

describe RBzip2::Compressor do

  before do
    @io = StringIO.new
    @bz2_compressor = RBzip2::Compressor.new @io
  end

  it 'acts like a standard IO' do
    methods = RBzip2::Compressor.instance_methods.map { |m| m.to_sym }
    methods.should include(:write, :close)
  end

  it 'should be able to compress raw data' do
    txt_file = File.new File.join(File.dirname(__FILE__), 'fixtures/test.txt')
    bz2_file  = File.new File.join(File.dirname(__FILE__), 'fixtures/test.bz2')
    @bz2_compressor.write txt_file.read
    @bz2_compressor.close

    eq_bz2 = eq bz2_file.read
    eq_bz2.instance_variable_set :@diffable, false
    @io.string.should eq_bz2
  end

  it 'should be able to compress large raw data' do
    txt_file = File.new File.join(File.dirname(__FILE__), 'fixtures/big_test.txt')
    bz2_file  = File.new File.join(File.dirname(__FILE__), 'fixtures/big_test.bz2')
    @bz2_compressor.write txt_file.read
    @bz2_compressor.close

    eq_bz2 = eq bz2_file.read
    eq_bz2.instance_variable_set :@diffable, false
    @io.string.should eq_bz2
  end

end
