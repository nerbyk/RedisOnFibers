module Request
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

  class QueryExecutor
    RESPS = {
      pong: 'PONG',
      err: 'ERR',
      ok: 'OK',
      ex: 'EX'
    }.freeze

    class Base
      class << self
        def echo(query) = query.args.join(' ')
        def ping(*) = RESPS[:pong]
        def error(query) = "#{RESPS[:err]} #{query.args.join(' ')}"
      end
    end

    class Storage
      class << self
        def set(storage, query)
          key, value = query.args

          storage[key] = value
          storage.add_time_event(key, options[1]) if query.options[0] == RESPS[:ex]

          RESPS[:ok]
        end

        def get(storage, query)
          storage[query.args.first]
        end

        def dbsize(storage, _)
          storage.size.to_s
        end
      end
    end

    def self.execute(query, default_executor: Base, storage: nil)
      if storage&.query_runner.respond_to?(query.command)
        storage.execute_query(query)
      elsif default_executor.respond_to?(query.command)
        default_executor.send(query.command, query)
      else
        raise ArgumentError, "Unknown command: #{query.command}"
      end
    end
  end
end
