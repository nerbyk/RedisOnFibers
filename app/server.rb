# frozen_string_literal: true

require 'socket'
require 'logger'
require 'delegate'
require 'async/scheduler'

require_relative 'async_logger'
require_relative 'storage'

Fiber.set_scheduler(Async::Scheduler.new)

class Server
  Request = Data.define(:command, :args) do
    def self.[](request_string)
      command, *args = request_string.split
      command = command.downcase.to_sym if command

      new(command:, args:)
    end
  end

  Query = Struct.new(:command, :args, :options) do
    QUERIES = { # rubocop:disable Lint/ConstantDefinitionInBlock
      set: -> (args) { { args: args[0..1], options: args[2..] } },
      get: -> (args) { { args: [args[0]] } },
      echo: -> (args) { { args: } },
      ping: -> (_) { {} },
      dbsize: -> (_) { {} }
    }

    def self.[](request)
      if QUERIES.key?(request.command)
        new(command: request.command, **QUERIES[request.command][request.args])
      else
        new(command: :error, args: ['ERR', 'Unknown command'])
      end
    end
  end

  Handler = lambda do |request_string, storage|
    request_string
      .then { |raw_request| Request[raw_request] }
      .then { |request| Query[request] }
      .then { |query| Storage::QueryExecutor[storage].execute(query) }
  end

  class FiberPool
    def initialize(max_fibers)
      @queue = Queue.new
      @fibers = Array.new(max_fibers) { create_fiber }
      @mutex = Mutex.new
    end

    def acquire(&block)
      @mutex.synchronize { @queue << block }
    end

    def start
      @fibers.each(&:resume)
    end

    private

    def create_fiber
      Fiber.new do
        loop do
          if (block = @queue.pop)
            block.call
          end
        end
      end
    end
  end

  PORT = ENV.fetch('PORT', 8080).to_i
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  TCP_BACKLOG = ENV.fetch('TCP_BACKLOG', '1024').to_i
  FIBER_POOL_SIZE = ENV.fetch('FIBER_POOL_SIZE', TCP_BACKLOG).to_i

  def initialize(storage:, logger:)
    @storage = storage
    @logger = logger.tap { |it| it.progname = self.class.name }
    @fibers_pool = FiberPool.new(FIBER_POOL_SIZE, &method(:handle_request))
  end

  def start
    @fibers_pool.start
    @logger.start_flusher if @logger.respond_to?(:start_flusher)

    Fiber.schedule do
      server = spawn_tcp_server

      loop do
        peer, _addr = server.accept

        log "Accepted connection from: #{peer.peeraddr.inspect}"

        @fibers_pool.acquire { handle_request(peer) }
      rescue => e
        log "Error accepting connection: #{e.message}", level: :error
        peer&.close
      end
    end
  end

  private

  def spawn_tcp_server
    TCPServer.new(HOST, PORT).tap do |it|
      it.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      it.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEPORT, true) if Socket.const_defined?(:SO_REUSEPORT)

      if RUBY_PLATFORM.include?('linux')
        it.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        it.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE, 50)
        it.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL, 10)
        it.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT, 5)
      else
        log 'Current socket KEEPALIVE setup linux supported only', level: :warn
      end

      it.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, [1, 0].pack('ii'))
      it.listen(TCP_BACKLOG)
    end.tap { |it| log "Server started at: #{it.addr.inspect}" }
  end

  def handle_request(peer)
    loop do
      next(Fiber.yield) unless (request = peer.gets("\n"))

      log "Received request: #{request.inspect} from: #{peer.peeraddr.inspect}"

      Handler.call(request, @storage)
        .then { |response| peer.puts(response) }
        .tap { |res| log "Sent response: #{res.inspect} to: #{peer.peeraddr.inspect}" }
    rescue => e
      log("Error handling request: #{e.message}", level: :error)
      log(e.backtrace.join("\n"), level: :error)
      peer&.close
    end
  end

  def log(msg, level: :info)
    @logger.public_send(level, msg)
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    TCPSocket.open(Server::HOST, Server::PORT).close
    raise 'Server already running'
  rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
    storage = Storage.new
    logger = ENV['DEBUG'] ? Logger.new($stdout) : AsyncLogger.new('logs/server.log')

    Server.new(storage:, logger:).start
  end
end

at_exit do
  puts 'Server is shutting down...'

  if $!
    logger.flush if defined?(logger) && logger.respond_to?(:flush)

    puts "Program exited due to an unhandled exception: #{$!.message}"
    puts $!.full_message
  end
end
