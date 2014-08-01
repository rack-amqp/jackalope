require 'spec_helper'

describe Rack::AMQP::Configuration do
  it 'yields a configuration' do
    x = nil
    Rack::AMQP.configure do |c|
      x = c
    end
    expect(x).to be_kind_of(Rack::AMQP::Configuration)
  end

  it 'allows configuration querying' do
    expect(Rack::AMQP.configuration).to_not be_nil
  end

  [
    :rabbit_host,
    :queue_name,
    :tls,
    :cert_chain_file,
    :private_key_file,
    :port,
    :username,
    :password
  ].each do |attr|
    it "accepts the #{attr} attribute" do
      Rack::AMQP.configure { |c| c.instance_variable_set("@#{attr}", 'foo') }
      expect(Rack::AMQP.configuration.instance_variable_get("@#{attr}")).to eql('foo')
    end
  end
end
