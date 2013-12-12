require 'pry'
module Rack
  module AMQP
    class Server

      def self.start(options={})
        new(options).start
      end

      attr_reader :options, :debug

      def initialize(options)
        @options = options
        @debug = options[:debug]
      end

      def server_agent
        "raqup-#{Rack::AMQP::VERSION}"
      end

      def start
        ::AMQP.start(host: 'localhost') do |client, open_ok|
          chan = ::AMQP::Channel.new(client)

          chan.queue("test.simple", auto_delete: true).subscribe do |metadata, payload|
            if debug
              puts "Received meta: #{metadata.inspect}"
              puts "Received message: #{payload.inspect}"
            end
            #binding.pry
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
          end

          puts "#{server_agent} running"
        end
      end

      def handle_request(meta, body)
        headers = meta.headers
        http_method = meta.type
        #user_agent = meta.app_id
        path = headers['path']

        parts = path.split(/\?/)
        uri = parts[0]
        query = parts[1] || ""

        env = ENV.to_hash
        env.update({
          "rack.version" => Rack::VERSION,
          "rack.input" => Rack::RewindableInput.new($stdin),
          "rack.errors" => $stderr,

          "rack.multithread" => false,
          "rack.multiprocess" => true,
          "rack.run_once" => true,

          "rack.url_scheme" => ["yes", "on", "1"].include?(ENV["HTTPS"]) ? "https" : "http",

          'REQUEST_METHOD' => http_method,
          'SERVER_NAME' => 'howdy',
          'SERVER_PORT' => '80',
          'PATH_INFO' => uri,
          'QUERY_STRING' => query,
          'HTTP_VERSION' => '1.1',
          'REQUEST_PATH' => uri,
        })
        response_code, headers, body = app.call(env)

        headers.merge!(
          'X-AMQP-HTTP-Status' => response_code
        )

        body_chunks = []
        body.each do |chunk| 
          #puts "chunk: #{chunk.inspect}"
          #binding.pry
          body_chunks << chunk
        end
        body.close

        [body_chunks.join, headers]
      end

      private

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
