require 'delegate'

class Storage < DelegateClass(Hash)
  TimeEvent = Data.define(:key, :process_at)

  class QueryExecutor < Data.define(:storage)
    RESPS = {
      ok: 'OK',
      pong: 'PONG',
      err: 'ERR',
      ex: 'EX'
    }

    def self.[](storage = Storage.new) = super

    def execute(query)
      raise ArgumentError, "Unknown command: #{query.command}" unless defined?("execute_#{query.command}")

      method("execute_#{query.command}").call(query)
    end

    private

    def execute_set(query)
      key, value = query.args

      storage[key] = value
      storage.add_time_event(key, options[1]) if query.options[0] == RESPS[:ex]

      RESPS[:ok]
    end

    def execute_get(query)
      storage[query.args.first]
    end

    def execute_echo(query)
      query.args.join(' ')
    end

    def execute_ping(_query)
      RESPS[:pong]
    end

    def execute_error(query)
      query.args.join(' ')
    end

    def execute_dbsize(_query)
      storage.size.to_s
    end
  end

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

  def execute(query)
    QueryExecutor[@storage].execute(query)
  end
end
