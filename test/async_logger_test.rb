require "test_helper"
require 'async_logger'

describe AsyncLogger do
  subject { AsyncLogger.new(file, ttl: buffer_ttl) }
  
  let(:buffer_ttl) { 1 }
  let(:file_path) { File.expand_path('logs/tests/async_logger_test.log' , __dir__ + '/../')}
  let(:file) { File.open(file_path) }

  def wait_for_flush = sleep(buffer_ttl + 1)

  before do
    File.open(file_path, 'w').close
    subject.start_flusher
  end

  it 'writes log messages to a file' do
    subject.log('INFO', 'Test log message')

    wait_for_flush

    assert_includes file.read, "Test log message"
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