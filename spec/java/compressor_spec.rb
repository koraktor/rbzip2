# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013-2017, Sebastian Staudt

require 'helper'

describe RBzip2::Java::Compressor do

  before do
    unless defined?(::RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
      pending 'Only available on JRuby'
    end
  end

  it_behaves_like 'a compressor'

end
