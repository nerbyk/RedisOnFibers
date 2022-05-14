require 'singleton'
require_relative './resp/types'
require_relative './resp/serializers'
class IncompleteRESP < StandardError; end

module RESP
  include Types
  include Serializers

  module_function

  def parse(resp_string)
    raise IncompleteRESP if resp_string.empty?

    return NullBulkStringInstance.parse if resp_string.start_with?(NULL_BULK_STRING)
    return NullArrayInstance.parse if resp_string.start_with?(NULL_ARRAY_STRING)

    resp_type = case resp_string[0]
    when '+' then RESPSimpleString.new SimpleStringSerializer[resp_string[1..]]
    when ':' then RESPInteger.new SimpleStringSerializer[resp_string[1..]]
    when '-' then RESPSimpleError.new SimpleStringSerializer[resp_string[1..]]
    when '$' then RESPBulkString.new(*BulkStringSerializer[resp_string])
    when '*' then RESPArray.new(*ArraySerializer[resp_string])
    else raise IncompleteRESP
    end

    resp_type.parse
  end

  def generate(object, with_bytesize: false)
    resp_type = case object
    when Integer then RESPInteger.new(object)
    when String then with_bytesize ? RESPBulkString.new(object) : RESPSimpleString.new(object)
    when Array then RESPArray.new(object)
    when NilClass then NullBulkStringInstance
    when StandardError then RESPSimpleError.new(object.message)
    else raise IncompleteRESP
    end

    resp_type.generate
  end
end
