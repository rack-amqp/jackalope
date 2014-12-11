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
      attr_accessor :root_path
      attr_accessor :rabbit_host, :rabbit_port
      attr_accessor :username, :password
      attr_accessor :queue_name
      attr_accessor :tls, :cert_chain_file, :private_key_file
      attr_accessor :daemonize, :pid_file, :stdout_file, :stderr_file
      attr_accessor :debug
      attr_accessor :heartbeat
      attr_accessor :prefetch
      
      def initialize
        default_options = {
          rabbit_host: 'localhost',
          rabbit_port: 5672,
          queue_name: 'default.queue',
          debug: false,
          tls: false,
          username: 'guest',
          password: 'guest',
          daemonize: false,
          heartbeat: 5,
          prefetch:  1
        }
        default_options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      def stderr_file
        @stderr_file || stdout_file
      end

      def connection_parameters
        params = {
          host: rabbit_host,
          port: rabbit_port,
          username: username,
          password: password,
          ssl: false,
          heartbeat: heartbeat,
          prefetch:  prefetch
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
