module Rack
  module AMQP
    class Server

      def self.start(options={})
        new(options).start
      end

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def start
        ::AMQP.start(host: 'localhost') do |client, open_ok|
          chan = ::AMQP::Channel.new(client)

          chan.queue("test.simple", auto_delete: true).subscribe do |payload|
            puts "Received message: #{payload.inspect}"
            response = handle_request payload
            chan.direct("").publish(response, routing_key: "test.simple.reply")
          end

          puts "go go go"
        end
      end

      def handle_request(uri)
        parts = uri.split(/\?/)
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

          'REQUEST_METHOD' => 'GET',
          'SERVER_NAME' => 'howdy',
          'SERVER_PORT' => '8080',
          'PATH_INFO' => uri,
          'QUERY_STRING' => query,
          'HTTP_VERSION' => '1.1',
          'REQUEST_PATH' => uri,
        })
        response_code, headers, body = app.call(env)
        response = []
        response << "Response code: #{response_code}"
        response << "Headers: #{headers.inspect}"
        response << "Body Follows:"
        body.each{|chunk| response << chunk }
        body.close
        response.join("\n")
      end

      private

      def app
        @app ||= construct_app(options[:rackup_file])
      end

      def construct_app rackup_file_name
        raw = ::File.read(rackup_file_name)
        app = eval("Rack::Builder.new {( #{raw} )}.to_app")
        racked_app = Rack::Builder.new do
          use Rack::ContentLength
          use Rack::Chunked
          use Rack::CommonLogger, $stderr
          run app
        end.to_app
      end

    end
  end
end
