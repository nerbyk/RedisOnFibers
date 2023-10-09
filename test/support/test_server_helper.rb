module TestServerHelper
  # TODO: Handle minitest multy-process execution
  def start_redis_server(host = '0.0.0.0', port = 6380)
    @port = port.to_s
    @host = host
    @pid = spawn_server_process
  end

  def stop_redis_server
    Process.kill('TERM', @pid)
    Process.wait(@pid)
  end

  def send_command(command)
    connection do |client|
      client.puts parsed_command(command)
      client.gets.chomp
    end
  end

  def send_commmands(*commands)
    commands.map { send_command(_1) }
  end

  def send_parallel_commands(*commands)
    commands.map do |command|
      Ractor.new(RESP, command, [@host, @port]) do |resp, c, (*opts)|
        res = TCPSocket.open(*opts) do |conn|
          conn.puts resp.generate(c.split(' '))
          conn.gets.chomp
        end

        Ractor.yield(res)
      end
    end.map(&:take)
  end

  private

  def connection = TCPSocket.new(@host, @port).tap { return yield(_1) }.close
  def parsed_command(c) = RESP.generate(c.split(' '))

  def spawn_server_process
    server_ready = false

    Signal.trap('USR1') { server_ready = true }

    pid = fork do
      exec 'ruby', "#{$SOURCE_PATH}/generate_test_server.rb", @host, @port
    end

    sleep(0.1) until server_ready

    Process.detach(pid)

    pid
  end
end

Minitest::Test.include TestServerHelper
