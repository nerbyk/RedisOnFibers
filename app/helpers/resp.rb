require 'singleton'
require_relative './resp/types'

module RESP
  include Types
  class RESPErrors < StandardError; end

  class IncompleteRESP < RESPErrors
    def message
      'Incomplete RESP'
    end
  end

  module_function

  def parse(resp_string)
    raise IncompleteRESP if resp_string.empty?

    return NullBulkStringInstance.decode if resp_string.start_with?(NULL_BULK_STRING)
    return NullArrayInstance.decode if resp_string.start_with?(NULL_ARRAY_STRING)

    resp_type = case resp_string.slice!(0)
    when '+' then RESPSimpleString.new(resp_string)
    when ':' then RESPInteger.new(resp_string)
    when '-' then RESPSimpleError.new(resp_string)
    when '$' then RESPBulkString.new(resp_string)
    when '*'
      callback = -> (rsp) { parse(rsp) }

      RESPArray.new(resp_string, callback)
    else raise IncompleteRESP
    end

    resp_type.decode
  rescue RESPErrors, RESPTypesError => e
    e.message
  end

  def generate(object, with_bytesize: false)
    resp_type = case object
    when Integer then RESPInteger.new(object)
    when String then with_bytesize ? RESPBulkString.new(object) : RESPSimpleString.new(object)
    when Array
      callback = -> (rsp) { generate(rsp) }

      RESPArray.new(object, callback)
    when NilClass then NullBulkStringInstance
    when StandardError then RESPSimpleError.new(object.message)
    else raise IncompleteRESP
    end

    resp_type.encode
  end
end
