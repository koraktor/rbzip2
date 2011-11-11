RBzip2
======

RBzip2 is a gem providing a pure Ruby implementation of the [bzip2][1]
algorithm used for compression and decompression.

It is based on the code of the [Apache Commons Compress][2] project and adds
a straight Ruby-like API. There are no external dependencies like other gems or
libraries. Therefore it will run on any Ruby implementation and the respective
operating systems supported by those implementations.

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

## Performance

Due to its pure Ruby implementation RBzip2 is inherently slower than
bzip2-ruby, which is a Ruby binding to libbzip2. Currently, RBzip2 is a plain
port of Apache Commons' Java code to Ruby and no effort has been made to
optimize it. That's why RBzip2 is slower by a factor of about 140/1000 while
compressing/decompressing (on Ruby 1.9.3). Ruby 1.8.7 is even slower.

## License

This code is free software; you can redistribute it and/or modify it under the
terms of the new BSD License. A copy of this license can be found in the
included LICENSE file.

## Credits

* Sebastian Staudt -- koraktor(at)gmail.com

## See Also

* [Documentation](http://rubydoc.info/gems/rbzip2)
* [GitHub project page](https://github.com/koraktor/rbzip2)
* [bzip2 project page][1]

 [1]: http://bzip.org
 [2]: http://commons.apache.org/compress
