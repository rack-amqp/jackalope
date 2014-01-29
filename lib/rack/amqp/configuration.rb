module Rack
  module AMQP
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    class Configuration
      attr_accessor :rabbit_host
      attr_accessor :queue_name
    end
  end
end
