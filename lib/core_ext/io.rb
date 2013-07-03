# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2013, Sebastian Staudt

unless IO.method_defined? :readbyte

  def IO.readbyte
    read(1)[0].ord
  end

end
