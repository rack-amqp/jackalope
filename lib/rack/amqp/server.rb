require "rack/amqp/configuration"

module Rack
  module AMQP
    class Server

      def self.start(options={})
        new(options).start
      end

      attr_reader :options, :debug

      def initialize(options)
        @options = options.dup
        @debug = options.delete(:debug)

        Rack::AMQP.configure do |config|
          options.each do |key, value|
            config.instance_variable_set("@#{key}", value)
          end
        end
      end

      def server_agent
        "jackalope-#{Rack::AMQP::VERSION}"
      end

      def configuration
        Rack::AMQP.configuration
      end

      def start
        ::AMQP.start(configuration.connection_parameters) do |client, open_ok|
          client.on_tcp_connection_loss do |connection, _|
            connection.reconnect(false, 10)
            subscribe_to_queue(configuration.queue_name, client)
          end

          subscribe_to_queue(configuration.queue_name, client)
        
          puts "#{server_agent} running"
        end
      end

      def handle_request(meta, body)
        headers     = meta.headers
        http_method = meta.type
        path        = headers['path']

        parts = path.split(/\?/)
        uri   = parts[0]
        query = parts[1] || ""

        env = default_env
        env.update({
          'REQUEST_METHOD' => http_method,
          'PATH_INFO' => uri,
          'QUERY_STRING' => query,
          'REQUEST_PATH' => uri,
          'CONTENT_LENGH' => headers['Content-Length'],
          'CONTENT_TYPE' => headers['Content-Type'],
          "rack.input" => StringIO.new(body)
        })

        # puts "call env: #{env.inspect}"

        response_code, headers, body = app.call(env)

        headers.merge!('X-AMQP-HTTP-Status' => response_code)

        body_chunks = []
        body.each { |chunk| body_chunks << chunk }
        body.close

        [body_chunks.join, headers]
      end

      private

      def subscribe_to_queue(name, session)
        chan  = ::AMQP::Channel.new(session)
        chan.prefetch(configuration.prefetch)
        queue = chan.queue(name, durable: true)

        queue.subscribe(ack: true) do |metadata, payload|
          if debug
            puts "Received meta: #{metadata.inspect}"
            puts "Received message: #{payload.inspect}"
          end
          response, headers = handle_request(metadata, payload)

          message_id = metadata.message_id
          reply_to = metadata.reply_to

          amqp_headers = {
            routing_key: reply_to,
            correlation_id: message_id,
            type: 'REPLY',
            app_id: server_agent,
            timestamp: Time.now.to_i,
            headers: headers
          }
          if type = headers['Content-Type']
            amqp_headers[:content_type] = type
          end
          if enc = headers['Content-Encoding']
            amqp_headers[:content_encoding] = enc
          end

          chan.direct("").publish(response, amqp_headers)

          metadata.ack
        end
      end
      
      
      def default_env
        @default_env = begin
                           env = ENV.to_hash
                           env.update({
                             "rack.version" => Rack::VERSION,
                             "rack.input" => Rack::RewindableInput.new($stdin),
                             "rack.errors" => $stderr,

                             "rack.multithread" => false,
                             "rack.multiprocess" => true,
                             "rack.run_once" => false,

                             "rack.url_scheme" => ["yes", "on", "1"].include?(ENV["HTTPS"]) ? "https" : "http",

                             'SERVER_NAME' => 'howdy',
                             'SERVER_PORT' => '80',
                             'HTTP_VERSION' => '1.1',
                           })
                         end
      end

      def app
        @app ||= construct_app(options[:rackup_file])
      end

      def construct_app rackup_file_name
        raw = ::File.read(rackup_file_name)
        app = eval("Rack::Builder.new {( #{raw} )}.to_app")
        Rack::Builder.new do
          use Rack::ContentLength
          # use Rack::Chunked TODO Maybe eventually
          use Rack::ShowExceptions
          use Rack::CommonLogger, $stderr
          run app
        end.to_app
      end
    end
  end
end
