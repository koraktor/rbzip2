# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2013, Brian Lopez
# Copyright (c) 2013, Sebastian Staudt

module RBzip2::FFI

  DEFAULT_BLK_SIZE    = 3

  BZ_RUN              = 0
  BZ_FLUSH            = 1
  BZ_FINISH           = 2

  BZ_OK               = 0
  BZ_RUN_OK           = 1
  BZ_FLUSH_OK         = 2
  BZ_FINISH_OK        = 3
  BZ_STREAM_END       = 4
  BZ_SEQUENCE_ERROR   = -1
  BZ_PARAM_ERROR      = -2
  BZ_MEM_ERROR        = -3
  BZ_DATA_ERROR       = -4
  BZ_DATA_ERROR_MAGIC = -5
  BZ_IO_ERROR         = -6
  BZ_UNEXPECTED_EOF   = -7
  BZ_OUTBUFF_FULL     = -8
  BZ_CONFIG_ERROR     = -9

end
