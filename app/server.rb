require 'socket'

class YourRedisServer
  def initialize(port)
    @server = TCPServer.new(port)
    puts "Listening on port #{port}"
  end

  def start
    loop do
      connection = @server.accept 
      handle(connection)
      puts("CLOSED")
    end
  end

  private

  def handle(connection)
    until connection.eof?
      request = connection.gets

      connection.close if request.nil?
      connection.puts('+PONG') unless connection.closed?
    end
  end
end

YourRedisServer.new(6379).start
