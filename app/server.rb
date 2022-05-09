require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    server = TCPServer.new(@port)

    loop do
      client = server.accept
      client_msg = client.gets

      puts(client_msg)

      # case client_msg
      # when /\+PING/ 
        client.puts("+PONG")
      # else 
      #   client.puts("+(error) unknown command '#{client_msg}'")
      # end

      client.close
    end 
  end
end

YourRedisServer.new(6379).start
