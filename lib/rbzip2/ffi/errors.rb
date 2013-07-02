# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Brian Lopez
# Copyright (c) 2013, Sebastian Staudt

module RBzip2::FFI

  class Error < StandardError; end
  class BufferError < Error; end
  class ConfigError < Error; end
  class CorruptError < Error; end

end
