require_relative 'helpers/resp'

class RequestHandler
  Request = Data.define(:raw_req) do
    attr_reader :command, :storage

    def initialize(raw_req:)
      @raw_request = raw_req
      @parsed_request = RESP.parse(raw_req)
      @command = @parsed_request.shift.downcase
    end

    def messages = @parsed_request
  end

  def self.process(raw_req, storage)
    new(Request[raw_req], storage).process
  end

  attr_reader :request, :storage

  def initialize(request, storage)
    @request = request
    @storage = storage
  end

  def process
    case request.command
    when /echo/
      RESP.generate(request.messages[0])
    when /get/
      RESP.generate(storage[request.messages[0]] || nil)
    when /set/
      (key, value, option, option_value) = request.messages

      storage[key] = value

      storage.add_time_event(key, Time.now.to_f.truncate + option_value) if option == /EX/ && option_value.to_i > 0

      RESP.generate('OK')
    else
      RESP.generate('PONG')
    end
  end
end
