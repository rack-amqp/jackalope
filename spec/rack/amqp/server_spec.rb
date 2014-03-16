require 'spec_helper'

describe Rack::AMQP::Server do
  it 'passes input to rack'
  it 'keeps running'

  it 'calls handle_request on event input'

  describe '#construct_app' do
    it 'builds a Rack app with the given rackup file inside'
  end

  describe '#default_env' do
    it 'looks like HTTP enough'
  end
end
