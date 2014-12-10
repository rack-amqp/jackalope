require "rack/amqp/configuration"

module Rack
  module AMQP
    class Server

      def self.start(options={})
        new(options).start
      end

      attr_reader :options

      def initialize(options)
        @options = options.dup

        Rack::AMQP.configure do |config|
          options.each do |key, value|
            config.instance_variable_set("@#{key}", value)
          end
        end
      end

      def server_agent
        "jackalope-#{Rack::AMQP::VERSION}"
      end

      def config
        Rack::AMQP.configuration
      end

      def start
        app

        check_pid! if config.pid_file

        daemonize_app if config.daemonize

        write_pid if config.pid_file

        ::AMQP.start(config.connection_parameters) do |client, open_ok|
          client.on_tcp_connection_loss do |connection, _|
            connection.reconnect(false, 10)
            subscribe_to_queue(config.queue_name, client)
          end

          subscribe_to_queue(config.queue_name, client)

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

        env = default_env.merge(headers.dup)
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

      def log(message)
        puts message if config.debug
      end

      private

        def subscribe_to_queue(name, session)
          chan  = ::AMQP::Channel.new(session)
          chan.prefetch(config.prefetch)
          queue = chan.queue(name, durable: true)

          queue.subscribe(ack: true) do |metadata, payload|
            log "Received meta: #{metadata.inspect}"
            log "Received message: #{payload.inspect}"

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
          @app ||= build_app(options[:rackup_file])
        end

        def build_app rackup_file_name
          app, _ = Rack::Builder.parse_file rackup_file_name
          Rack::Builder.new do
            use Rack::ContentLength
            # use Rack::Chunked TODO Maybe eventually
            use Rack::ShowExceptions
            use Rack::CommonLogger, $stderr
            run app
          end.to_app
        end

        def daemonize_app
          if RUBY_VERSION < "1.9"
            exit if fork
            Process.setsid
            exit if fork
            Dir.chdir "/"
          else
            Process.daemon
          end
          STDIN.reopen "/dev/null"
          STDOUT.reopen config.stdout_file, "a"
          STDERR.reopen config.stderr_file, "a"
        end

        def write_pid
          ::File.open(config.pid_file, ::File::CREAT | ::File::EXCL | ::File::WRONLY ){ |f| f.write("#{Process.pid}") }
          at_exit { ::File.delete(config.pid_file) if ::File.exist?(config.pid_file) }
        rescue Errno::EEXIST
          check_pid!
          retry
        end

        def check_pid!
          case pidfile_process_status
          when :running, :not_owned
            $stderr.puts "A server is already running. Check #{config.pid_file}."
            exit(1)
          when :dead
            ::File.delete(config.pid_file)
          end
        end

        def pidfile_process_status
          return :exited unless ::File.exist?(config.pid_file)

          pid = ::File.read(config.pid_file).to_i
          Process.kill(0, pid)
          :running
        rescue Errno::ESRCH
          :dead
        rescue Errno::EPERM
          :not_owned
        end
    end
  end
end
