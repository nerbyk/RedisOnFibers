require 'test_helper'
require 'async_logger'

describe AsyncLogger do
  subject { AsyncLogger.new(file, ttl: buffer_ttl) }

  let(:buffer_ttl) { 1 }
  let(:file_path) { File.expand_path('logs/tests/async_logger_test.log', __dir__ + '/../') }
  let(:file) { File.open(file_path) }

  def wait_for_flush = sleep(buffer_ttl + 1)

  describe 'logging' do
    before do
      subject.start_flusher
    end

    it 'writes log messages to a file' do
      subject.log('INFO', 'Test log message')

      wait_for_flush

      assert_includes file.read, 'Test log message'
    end

    it 'writes multiple log messages to a file' do
      5.times.map do
        Thread.new do
          50.times { subject.log('INFO', 'Test log message') }
        end
      end.each(&:join)

      wait_for_flush

      assert_equal 250, file.read.split("\n").size
    end
  end

  describe 'buffering' do
    let(:log_message) { 'Test buffering' }
    let(:formated_log_message) { subject.send(:format_message, 'INFO', Time.now, nil, log_message) }

    it 'flushes the buffer on exit' do
      fork do
        subject.log('INFO', log_message)
        exit
      end.tap(&Process.method(:wait))

      assert_equal file.size, formated_log_message.size
    end

    it 'flushes the buffer on max size' do
      subject.class::MAX_BUFFER_SIZE.times { subject.log('INFO', log_message) }

      assert_equal file.size, 0

      subject.log('INFO', log_message)

      assert_equal file.size, (subject.class::MAX_BUFFER_SIZE + 1) * formated_log_message.size
    end
  end
end
