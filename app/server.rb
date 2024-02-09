# frozen_string_literal: true

require 'socket'
require 'logger'
require 'delegate'
require 'async/scheduler'

Fiber.set_scheduler(Async::Scheduler.new)

class Server
  class Storage < DelegateClass(Hash)
    TimeEvent = Data.define(:key, :process_at)

    def initialize(data: {})
      @time_events = []
      @mutex = Mutex.new
      super(data)
    end

    def [](key)
      @mutex.synchronize { super }
    end

    def []=(key, value)
      @mutex.synchronize { super }
    end

    def add_time_event(key, process_at)
      @mutex.synchronize { @time_events << TimeEvent.new(key, process_at) }
    end
  end

  class QueryExecutor
    @storage = Storage.new

    RESPS = {
      ok: 'OK',
      pong: 'PONG',
      err: 'ERR',
      ex: 'EX'
    }

    def self.execute(query)
      COMMANDS_EXECUTORS[query.command].call(query)
    end

    def self.execute_set(query)
      key, value = query.args

      @storage[key] = value
      @storage.add_time_event(key, options[1]) if query.options[0] == RESPS[:ex]

      RESPS[:ok]
    end

    def self.execute_get(query)
      @storage[query.args.first]
    end

    def self.execute_echo(query)
      query.args.join(' ')
    end

    def self.execute_ping(_query)
      RESPS[:pong]
    end

    def self.execute_err(query)
      query.args.join(' ')
    end

    COMMANDS_EXECUTORS = {
      set: method(:execute_set),
      get: method(:execute_get),
      echo: method(:execute_echo),
      ping: method(:execute_ping),
      error: method(:execute_err)
    }
  end

  Request = Data.define(:command, :args) do
    def self.[](request_string)
      command, *args = request_string.split
      command = command.downcase.to_sym

      new(command:, args:)
    end
  end

  Query = Struct.new(:command, :args, :options) do
    QUERIES = { # rubocop:disable Lint/ConstantDefinitionInBlock
      set: -> (args) { { args: args[0..1], options: args[2..] } },
      get: -> (args) { { args: [args[0]] } },
      echo: -> (args) { { args: } },
      ping: -> (_) { {} }
    }

    def self.[](request)
      if QUERIES.key?(request.command)
        new(command: request.command, **QUERIES[request.command][request.args])
      else
        new(command: :error, args: ['ERR', 'Unknown command'])
      end
    end
  end

  PORT = ENV.fetch('PORT', 3000).to_i
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  TCP_BACKLOG = ENV.fetch('TCP_BACKLOG', '1024').to_i

  def initialize
    @logger = Logger.new($stdout)
  end

  def start
    Fiber.schedule do
      server = TCPServer.new(HOST, PORT)
      server.listen(TCP_BACKLOG)

      log 'Listening on: ' + server.local_address.inspect

      loop do
        conn, _addr = server.accept
          .tap { |conn| log "Accepted connection from: #{conn.peeraddr.inspect}" }

        Fiber.schedule do
          next unless (req = conn.gets("\n"))

          req.tap { |received_msg| log "Received message: #{received_msg.inspect}" }
            .then { |raw_request| Request[raw_request] }
            .then { |request| Query[request] }
            .then { |query| QueryExecutor.execute(query) }
            .then { |response| conn.puts(response) }
        rescue => e
          log "Error: #{e.full_message}", level: :error
          conn&.close
        end
      rescue => e
        log "Error accepting connection: #{e.message}", level: :error
        conn&.close
      end
    end
  end

  private def log(msg, level: :info)
    @logger.public_send(level, msg)
  end
end

Server.new.start if $PROGRAM_NAME == __FILE__
