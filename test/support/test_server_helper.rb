module TestServerHelper
  ConnectionOptions = Data.define(:host, :port) do  
    def initialize(port: '6380', host: '0.0.0.0') = super
    def values = to_h.values
  end

  Connection = Data.define(:options) do
    def initialize(options = ConnectionOptions.new) = super
    def run = TCPSocket.open(*options.values) { yield(_1) }
  end

  CommandRunner = lambda do |command, connection|
    connection.run do |client|
      client.puts RESP.generate(command.split(' '))
      client.gets.chomp
    end
  end

  def start_redis_server()
    @conn_opts = ConnectionOptions.new.freeze
    @pid = spawn_server_process
  end
  
  def stop_redis_server
    Process.kill('TERM', @pid)
    Process.wait(@pid)
  end
  
  def send_command(command)
    CommandRunner.call(command, Connection[@conn_opts])
  end
  
  def send_commmands(*commands)
    commands.map { send_command(_1) }
  end
  
  def send_parallel_commands(*commands)
    Ractor.make_shareable(CommandRunner)

    commands.map do |command|
      Ractor.new(command, Connection[@conn_opts]) do |cmd, conn|
        Ractor.yield(CommandRunner[cmd, conn])
      end
    end.map(&:take)
  end
  
  private def spawn_server_process(opts = @conn_opts)
    server_ready = false

    Signal.trap('USR1') { server_ready = true }

    pid = fork do
      exec 'ruby', "#{$SOURCE_PATH}/generate_test_server.rb", opts.host, opts.port
    end

    sleep(0.1) until server_ready

    Process.detach(pid)

    pid
  end
end

Minitest::Test.include TestServerHelper
