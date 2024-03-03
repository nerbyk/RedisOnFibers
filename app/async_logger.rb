require 'logger'

class AsyncLogger < Logger
  DEFAULT_LOG_FILE = 'logs/async_logger.log'.freeze
  DEFAULT_BUFFER_TTL = 5
  DEFAULT_SHIFT_AGE = 'daily'.freeze
  MAX_BUFFER_SIZE = 10_000

  def initialize(io_source = DEFAULT_LOG_FILE, shift_age = DEFAULT_SHIFT_AGE, ttl: DEFAULT_BUFFER_TTL, truncate: true)
    @io_source = File.open(io_source, truncate ? 'w' : 'a')
    @buffer = []
    @mutex = Mutex.new
    @ttl = ttl
    super(@io_source, shift_age)
  end

  def start_flusher
    Thread.start do
      loop do
        sleep(@ttl)
        flush
      end
    end
  end

  def log(severity, message = nil, progname = nil)
    @mutex.synchronize { @buffer << format_message(severity, Time.now, progname, message) }
    flush if @buffer.size >= MAX_BUFFER_SIZE
  end

  def flush
    @mutex.synchronize do
      File.write(@io_source, @buffer.join, mode: 'a')
      @buffer.clear
    end
  end
end
