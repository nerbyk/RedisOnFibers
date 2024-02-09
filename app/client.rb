require 'socket'
require 'logger'
require 'delegate'

class Client
  class Connection < SimpleDelegator
    PORT = ENV.fetch('PORT', 3000).to_i
    HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  
    def initialize
      @logger = Logger.new($stdout)
      super TCPSocket.new(HOST, PORT)
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
  end

  def connection(&block)
    @connection = Connection.new if @connection.nil? || @connection.closed? 

    return @connection unless block_given?

    @connection.tap do |conn|
      instance_eval(&block)
    ensure 
      conn.close
    end
  rescue => e
    puts "Error: #{e.full_message.split("\n").first(5).join("\n")}"
  end

  private 

  def request(request_string, peer: connection)
    peer.send_request(request_string)
  end

  def receive(peer: connection)
    if res = peer.read_response
      res
    else 
      nil
    end
  end
end

Client.new.tap do |client|
  puts "BYO Redis Client"

  loop do
    print "> "
    command = gets

    response = client.connection do
      request(command)
      receive
    end
  end
end if $PROGRAM_NAME == __FILE__
