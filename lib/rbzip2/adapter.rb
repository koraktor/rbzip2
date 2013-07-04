# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Sebastian Staudt

module RBzip2::Adapter

  def self.extended(mod)
    mod.send :class_variable_set, :@@available, true
    mod.init if mod.respond_to? :init
  end

  def available?
    class_variable_get :@@available
  end

end
