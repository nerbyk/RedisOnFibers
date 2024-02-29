require 'socket'
require 'logger'
require 'delegate'

class Client
  class Connection < SimpleDelegator
    PORT = ENV.fetch('PORT', 8080).to_i
    HOST = ENV.fetch('HOST', '127.0.0.1').freeze
    MAX_RETRIES = ENV.fetch('MAX_RETRIES', 10).to_i

    DISABLE_LOG = ENV.fetch('DISABLE_LOG', false)

    def initialize
      @logger = setup_logger

      begin
        super TCPSocket.new(HOST, PORT)
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL => e
        retries = (retries ||= 0) + 1
        raise e if retries > MAX_RETRIES
        sleep(3 * (0.5 + rand / 2) * 1.5**(retries - 1)) # exponential backoff
        retry
      end
    end

    def send_request(req)
      self.puts(req).tap do
        @logger.info "Sent request: #{req.inspect}"
      end
    end

    def read_response(timeout: 5)
      self.gets("\n").tap do |res|
        @logger.info "Received response: #{res.inspect}"
      end.then { |res| res&.encode('UTF-8') }
    end

    def setup_logger
      Logger.new(DISABLE_LOG ? nil : $stdout)
        .tap { |it| it.progname = self.class.name }
    end
  end

  def connection(&block)
    @connection = Connection.new if @connection.nil? || @connection&.closed?

    instance_eval(&block) if block

    @connection
  rescue => e
    @connection&.close if @connection.respond_to?(:close)
    raise e
  end

  private

  def request(request_string, peer: connection)
    peer.send_request(request_string)
  end

  def receive(peer: connection)
    peer.read_response
  end
end

if $PROGRAM_NAME == __FILE__
  Client.new.tap do |client|
    puts 'BYO Redis Client'

    loop do
      print '> '
      command = gets

      client.connection do
        request(command)
        receive
      end
    end
  end
end
