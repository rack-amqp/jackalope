require 'spec_helper'

describe Rack::AMQP::Configuration do
  it 'yields a configuration' do
    x = nil
    Rack::AMQP.configure do |c|
      x = c
    end
    refute_nil x
  end

  it 'allows configuration querying' do
    refute_nil Rack::AMQP.configuration
  end

  it 'accepts the rabbit host' do
    Rack::AMQP.configure { |c|      c.rabbit_host = 'foo' }
    Rack::AMQP.configuration.rabbit_host.must_equal 'foo'
  end

  it 'accepts the queue name' do
    Rack::AMQP.configure { |c|      c.queue_name = 'bar' }
    Rack::AMQP.configuration.queue_name.must_equal 'bar'
  end
end
