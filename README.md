[![Build Status](https://travis-ci.org/rack-amqp/jackalope.png?branch=master)](https://travis-ci.org/rack-amqp/jackalope)

# Jackalope

![Jackalope](http://beerpulse.com/wp-content/uploads/2010/11/jackalope-brewing.png)

AMQP-HTTP compliant Server to run your rack (rails) application using
AMQP as the transport protocol.

## Installation

Add this line to your application's Gemfile:

    gem 'jackalope'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jackalope

## Usage

    jackalope -q <queue name> <rackup file>

for rails app:

    jackalope -q my.queue config.ru

all parameters:

| Parameters    |                     Description                    | Default Value |
|---------------|:--------------------------------------------------:|--------------:|
| -q, --queue   | rabbitmq queue name for application communication  | default.queue |
| -s, --server  |         rabbitmq server host or IP address         |     localhost |
| -p, --port    |                rabbitmq server port                |          5672 |
| -u, --user    | username to use for the rabbitmq server connection |         guest |
| -P, --pass    | password to use for the rabbitmq server connection |         guest |
| -t, --tls     |   use TLS when connecting to the rabbitmq server   |         false |
| -c, --cert    | path to the client certificate (pem format)        |           nil |
| -k, --key     | path to the client private key (pem format)        |           nil |
| -d, --debug   |           turn on some debugging messages          |         false |
| -h, --help    |                show the help dialog                |           N/A |
| -v, --version |                  show the version                  |           N/A |

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
