# frozen_string_literal: true

require 'socket'
require 'evt'
require_relative './request_handler'

class Server
  Storage = Data.define(:data) do
    TimeEvent = Struct.new(:key, :process_at)

    def initialize(data: {})
      @data = data
      @time_events = []
      @mutex = Mutex.new
    end

    def [](key)
      @mutex.synchronize { @data[key] }
    end

    def []=(key, value)
      @mutex.synchronize { @data[key] = value }
    end

    def add_time_event(key, process_at)
      @mutex.synchronize { @time_events << TimeEvent.new(key, process_at) }
    end
  end

  def initialize(host, port, handler: RequestHandler)
    @server = TCPServer.new(host, port)
    @clients = []
    @handler = handler
    @storage = Storage.new

    at_exit { stop }

    puts "Listening on port #{port}"
  end

  def stop
    @server.close
    @clients.each(&:close)
  end

  def start
    Fiber.set_scheduler(Evt::Scheduler.new)

    Fiber.schedule do
      loop do
        new_client = @server.accept_nonblock
        @clients << new_client

        Fiber.schedule { serve_client(new_client) }
      rescue IO::WaitReadable, Errno::EINTR
        @server.wait_readable
        retry
      end
    end
  end

  private

  def serve_client(client)
    loop do
      client_message = client.read_nonblock(256, exception: false)

      @clients.delete(client) if client.closed?
      next if client_message == :wait_readable || client_message.nil?

      response = @handler.process(client_message, @storage)
      client.puts response

      Fiber.yield
    end
  end
end
