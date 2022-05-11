require 'socket'

class YourRedisServer
  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    puts "Listening on port #{port}"
  end

  def start
    Thread.new do
      loop do
        new_client = @server.accept
        @clients << new_client
      end
    end

    loop do
      sleep(0.1) if @clients.empty?

      @clients.each_with_index do |client|
        client_command = client.read_nonblock(256, exception: false)

        @clients.delete(client) if client.closed?
        next if client_command == :wait_readable || client_command.nil?

        response = handle_client_command(client_command)
        client.puts response
      end
    end
  end

  private

  def handle_client_command(_command)
    "+PONG"
  end
end

YourRedisServer.new(6379).start
