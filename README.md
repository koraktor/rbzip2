RBzip2
======

RBzip2 is a gem providing various implementations of the [bzip2][bzip2]
algorithm used for compression and decompression. Currently, it includes a
[FFI][ffi]-based implementation and a pure Ruby implementation that's slower
but works on any Ruby VM. Additionally, there's a JRuby specific implementation
that's based on Commons Compress.

The pure Ruby implementations is based on the code of the
[Apache Commons Compress][commons] project and adds a straight Ruby-like API.
There are no external dependencies like other gems or libraries. Therefore it
will run on any Ruby implementation and the respective operating systems
supported by those implementations.

The FFI implementation is using `libbz2` and provides fast performance on
platforms where both `libbz2` and FFI are available. It is derived from this
[Gist by Brian Lopez][gist].

The Java-based implementation can use the
[Commons Compress Java library][commons] if it is available in the classpath.

## Features

 * Compression of raw data into bzip2 compressed `IO`s (like `File` or
   `StringIO`)
 * Decompression of bzip2 compressed `IO`s (like `File` or `StringIO`)

## Usage

    require 'rbzip2'

### Compression

    data = some_data
    file = File.new 'somefile.bz2'      # open the target file
    bz2  = RBzip2::Compressor.new file  # wrap the file into the compressor
    bz2.write data                      # write the raw data to the compressor
    bz2.close                           # finish compression (important!)

### Decompression

    file = File.new 'somefile.bz2'        # open a compressed file
    bz2  = RBzip2::Decompressor.new file  # wrap the file into the decompressor
    data = io.read                        # read data into a string

## Future plans

 * Simple decompression of strings
 * Simple creation of compressed files
 * Two-way compressed IO that will (de)compress as you read/write

## Installation

To install RBzip2 as a Ruby gem use the following command:

    gem install rbzip2

To use it as a dependency managed by Bundler add the following to your
`Gemfile`:

    gem 'rbzip2'

If you want to use the FFI implementation on any non-JRuby VM, be sure to also
install the `ffi` gem.

## Performance

The `bzip2-ruby` gem is a Ruby binding to `libbz2` and offers best performance,
but it is only available for MRI < 2.0.0 and Rubinius.

The FFI implementation binds to `libbz2` as well and has almost the same
performance as `bzip2-ruby`.

The Java implementation uses a native Java library and is slower by a factor of
about 2/10 while compressing/decompressing.

The pure Ruby implementation of RBzip2 is inherently slower than `bzip2-ruby`.
Currently, this is a plain port of Apache Commons' Java code to Ruby and no
effort has been made to optimize it. That's why the Ruby implementation of
RBzip2 is slower by a factor of about 130/100 while compressing/decompressing
(on Ruby 1.9.3). Ruby 1.8.7 is even slower.

## License

This code is free software; you can redistribute it and/or modify it under the
terms of the new BSD License. A copy of this license can be found in the
included LICENSE file.

## Credits

* Sebastian Staudt -- koraktor(at)gmail.com
* Brian Lopez -- seniorlopez(at)gmail.com

## See Also

* [Documentation](http://rubydoc.info/gems/rbzip2)
* [GitHub project page](https://github.com/koraktor/rbzip2)
* [bzip2 project page][bzip2]

 [bzip2]:   http://bzip.org
 [commons]: http://commons.apache.org/compress
 [ffi]:     https://github.com/ffi/ffi/wiki
 [gist]:    https://gist.github.com/brianmario/5833373
