require 'client'

module TestServerHelper
  CommandRunner = ->(command, client) do
    client.connection do 
      request(command)
      return receive.chomp
    end
  end

  def start_redis_server
    @pid = spawn_server_process
    @client = Client.new
  end
  
  def stop_redis_server
    Process.kill('TERM', @pid)
    Process.wait(@pid)
  end
  
  def send_command(command, client: @client)
    CommandRunner[command, client]
  end
  
  def send_commmands(*commands)
    commands.map(&method(:send_command))
  end
  
  def send_parallel_commands(*commands)
    Ractor.make_shareable(Client)
    Ractor.make_shareable(CommandRunner)

    commands.map do |command|
      Ractor.new(command, Client.new) do |cmd, client|
        Ractor.yield CommandRunner[cmd, client]
      end
    end.map(&:take)
  end
  
  private def spawn_server_process
    raise "Server already running" if server_running?

    pid = fork do
      exec "ruby", "#{$SOURCE_PATH}/server.rb"
    end

    wait_for_tcp_socket

    pid
  end

  def wait_for_tcp_socket(timeout: 5)
    start_time = Time.now
    
    while ((Time.now - start_time) < timeout)
      return if server_running?

      sleep 0.1
      puts 'Waiting for server to start...'
    end

    raise "Server did not start in #{timeout} seconds"
  end

  def server_running?
    TCPSocket.open(::Client::Connection::HOST, Client::Connection::PORT).close
    true
  rescue Errno::ECONNREFUSED
    false
  end
end

Minitest::Test.include TestServerHelper
