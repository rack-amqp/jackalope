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
      attr_accessor :tls
      attr_accessor :cert_chain_file
      attr_accessor :private_key_file
      attr_accessor :port
      attr_accessor :username
      attr_accessor :password
      attr_accessor :heartbeat
      attr_accessor :prefetch

      def connection_parameters
        params = {
          host:      rabbit_host || 'localhost',
          port:      port        || 5672,
          username:  username    || 'guest',
          password:  password    || 'guest',
          ssl:       false,
          heartbeat: heartbeat   || 5,
          prefetch:  prefetch    || 1
        }

        if tls
          params[:ssl] = true
          if cert_chain_file && private_key_file
            params[:ssl] = {
              cert_chain_file: cert_chain_file,
              private_key_file: private_key_file
            }
          end
        end
        params
      end
    end
  end
end
