require 'rack'
require 'amqp'
require 'rack/content_length'
require 'rack/rewindable_input'

module Rack
  module AMQP
  end
end

require 'rack/amqp/version'
require 'rack/amqp/server'
