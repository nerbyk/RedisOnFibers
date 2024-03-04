require 'delegate'

class Storage < DelegateClass(Hash)
  TimeEvent = Data.define(:key, :process_at)

  def initialize(data: {})
    @time_events = []
    @mutex = Mutex.new
    super(data)
  end

  def [](...)
    @mutex.synchronize { super }
  end

  def []=(...)
    @mutex.synchronize { super }
  end

  def add_time_event(key, process_at)
    @mutex.synchronize { @time_events << TimeEvent.new(key, process_at) }
  end

  def execute_query(query)
    query_runner.send(query.command, self, query)
  end

  def query_runner = Request::QueryExecutor::Storage
end
