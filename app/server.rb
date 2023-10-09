# frozen_string_literal: true

require 'socket'
require_relative './helpers/resp'
class Server
  TimeEvent = Struct.new(:key, :process_at)

  def initialize(host, port)
    @server = TCPServer.new(host, port)

    @clients = []
    @storage = {}
    @time_events = []

    at_exit { stop }

    puts "Listening on port #{port}"
  end

  def stop
    @server.close
    @clients.each(&:close)
  end

  def start
    Thread.new do
      loop do
        new_client = @server.accept
        @clients << new_client
      end
    end

    loop do
      sleep(1) if @clients.empty?

      @clients.each do |client|
        client_message = client.read_nonblock(256, exception: false)

        @clients.delete(client) if client.closed?
        next if client_message == :wait_readable || client_message.nil?

        response = handle_client_command(client_message)
        client.puts response
      end

      process_time_events
    end
  end

  private

  def handle_client_command(message)
    request_message = RESP.parse(message)
    command = request_message.shift.downcase

    case command
    when /echo/
      RESP.generate(request_message[0])
    when /get/
      RESP.generate(@storage[request_message[0]] || nil)
    when /set/
      (key, value, option, option_value) = request_message

      @storage[key] = value

      add_time_event(key, Time.now.to_f.truncate + option_value) if option == /EX/ && option_value.to_i > 0

      RESP.generate('OK')
    else
      RESP.generate('PONG')
    end
  end

  def add_time_event(key, process_at)
    @time_events << TimeEvent.new(key, process_at)
  end

  def process_time_events
    @time_events.delete_if do |time_event|
      !!@storage.delete(time_event.key) if time_event.process_at <= Time.now.to_f
    end
  end
end
