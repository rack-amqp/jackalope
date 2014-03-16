[![Build Status](https://travis-ci.org/rack-amqp/jackalope.png?branch=master)](https://travis-ci.org/rack-amqp/jackalope)

# Jackalope

![Jackalope](http://beerpulse.com/wp-content/uploads/2010/11/jackalope-brewing.png)

Server to run your rack (rails) application using AMQP as the transport
protocol.

## Installation

Add this line to your application's Gemfile:

    gem 'jackalope'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jackalope

## Usage

    jackalope <rackup file>

for rails app:

    jackalope config.ru

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
