require 'spec_helper'

describe Rack::AMQP::Configuration do
  it 'yields a configuration' do
    x = nil
    Rack::AMQP.configure do |c|
      x = c
    end
    expect(x).to_not be_nil
  end

  it 'allows configuration querying' do
    expect(Rack::AMQP.configuration).to_not be_nil
  end

  it 'accepts the rabbit host' do
    Rack::AMQP.configure { |c|      c.rabbit_host = 'foo' }
    expect(Rack::AMQP.configuration.rabbit_host).to eql('foo')
  end

  it 'accepts the queue name' do
    Rack::AMQP.configure { |c|      c.queue_name = 'bar' }
    expect(Rack::AMQP.configuration.queue_name).to eql('bar')
  end
end
