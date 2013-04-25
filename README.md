# StormFly::Image

This gem provides tools for generating, managing and burning StormFly images.

## Installation

Add this line to your application's Gemfile:

    gem 'stormfly-image'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stormfly-image

## Generating the gem

Run rake -T to see available tasks. The gem can be built with:

    $ rake build

Or, if you want to make sure everything works correctly:

    $ bundle exec rake build

Note that the gem version will be that specified in StormFly::Image::VERSION,
regardless of modifications to other files.

## Usage

Provided binaries are 'sfi_gen' and 'sfi_burn'. Run them without arguments to
see an usage help message.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
