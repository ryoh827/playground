# frozen_string_literal: true

require 'socket'
require 'logger'
require 'rack/rewindable_input'
require 'rack/runtime'

class App
  def call(env)
    if env['PATH_INFO'] == '/'
      [200, {}, ['It works!']]
    elsif env['PATH_INFO'] == '/ping'
      [200, {}, ['pong']]
    else
      [404, {}, ['Not Found']]
    end
  end
end

class PreforkServer
  PROCESS_COUNT = 2

  def self.run(app, **options)
    new(app, options).start
  end

  def initialize(app, options)
    @app = app
    @options = options
    @logger = Logger.new($stdout)
  end

  def start
    write_pid

    socket = TCPServer.new(@options[:Host], @options[:Port].to_i)

    workers = []

    PROCESS_COUNT.times do
      workers << fork do
        loop do
          conn, _addr_info = socket.accept
          request_line = conn.gets&.chomp
          %r{^GET (?<path>.+) HTTP/1.1$}.match(request_line)
          path = Regexp.last_match(:path)
          raise unless path

          # headers
          headers = {}
          while /^(?<name>[^:]+):\s+(?<value>.+)$/.match(conn.gets.chomp)
            headers[Regexp.last_match(:name)] = Regexp.last_match(:value)
          end

          env = ENV.to_hash.merge(
            Rack::REQUEST_METHOD => 'GET',
            Rack::SCRIPT_NAME => '',
            Rack::PATH_INFO => path,
            Rack::SERVER_NAME => @options[:Host],
            Rack::RACK_INPUT => Rack::RewindableInput.new(conn),
            Rack::RACK_ERRORS => $stderr,
            Rack::QUERY_STRING => '',
            Rack::REQUEST_PATH => path,
            Rack::RACK_URL_SCHEME => 'http',
            Rack::SERVER_PROTOCOL => 'HTTP/1.1'
          )
          headers.each do |head|
            env["HTTP_#{head[0].upcase.gsub('-', '_')}"] = head[1]
          end
          @app.call(env) => status, response_headers, body

          conn.puts "HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"

          response_headers.each do |name, value|
            conn.puts "#{name}: #{value}"
          end
          conn.puts
          body.each do |line|
            conn.puts line
          end
        rescue StandardError => e
          @logger.error e.message
          conn.puts 'HTTP/1.1 500 Internal Server Error'
        ensure
          conn&.close
        end
      end
    end

    trap(:TERM) do
      workers.each { |worker| Process.kill(:TERM, worker) }
    end
    trap(:INT) do
      workers.each { |worker| Process.kill(:TERM, worker) }
    end
    workers.each { Process.waitpid(_1) }
  end

  private

  def write_pid
    File.write('tmp/server.pid', Process.pid)
  end
end

Rackup::Handler.register 'prefork_server', PreforkServer

use Rack::Runtime
run App.new
