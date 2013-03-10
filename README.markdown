# Gerber

Everything you need to read and write Gerber RS-274-D and [Extended Gerber RS-274X](http://en.wikipedia.org/wiki/Gerber_Format) files

Files created by this gem conform to the latest [Gerber format specification](http://www.ucamco.com/Portals/0/Public/The_Gerber_File_%20Format_Specification.pdf)

## Installation

Add this line to your application's Gemfile:

    gem 'gerber'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gerber

## Usage

```ruby
require 'gerber'

gerber = Gerber.read('somefile.gerber')
gerber.write('outfile.gerber')
```

License
-------

Copyright 2012-2013 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
