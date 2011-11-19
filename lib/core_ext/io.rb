# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

unless IO.method_defined? :readbyte

  class IO

    def readbyte
      read(1)[0].ord
    end

  end

end
