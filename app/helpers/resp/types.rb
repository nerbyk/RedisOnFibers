module RESP
  module Types
    TYPES = [
      SIMPLE_STRING = '+',
      INTEGER = ':',
      ERROR = '-',
      BULK_STRING = '$',
      ARRAY = '*'
    ].freeze

    NULL_BULK_STRING = "$-1\r\n".freeze
    NULL_ARRAY_STRING = "*-1\r\n".freeze

    SERIALIZED_SIMPLE_TYPE = -> (rsp) {
      rsp.tap do |str|
        str.chomp!
        str.tr!("\r\n", '')
        str.gsub!(/ {2,}/, ' ')
      end
    }

    class RESPTypesError < StandardError; end

    class InvalidRESPType < RESPTypesError
      def initialize(message = 'Protocol type error', expected:, got:)
        super(message + ": expected #{expected}, got #{got}")
      end
    end

    class IncompleteRESP < RESPTypesError
      def initialize(message = 'Incomplete RESP')
        super(message)
      end
    end

    RESPInteger = Struct.new(:underlying_integer) do
      def encode
        ":#{underlying_integer}\r\n"
      end

      def decode
        SERIALIZED_SIMPLE_TYPE[underlying_integer].to_i
      end
    end

    RESPSimpleString = Struct.new(:underlying_string) do
      def encode
        "+#{underlying_string}\r\n"
      end

      def decode
        SERIALIZED_SIMPLE_TYPE[underlying_string]
      end
    end

    RESPSimpleError = Struct.new(:underlying_error) do
      def encode
        "-ERR #{underlying_error}\r\n"
      end

      def decode
        SERIALIZED_SIMPLE_TYPE[underlying_error]
      end
    end

    RESPBulkString = Struct.new(:underlying_string) do
      def encode
        "$#{underlying_string.bytesize}\r\n#{underlying_string}\r\n"
      end

      def decode
        (bytesize, resp_string) = underlying_string.rpartition(/\d+/)[1..]
        bytesize = bytesize.to_i
        underlying_string = SERIALIZED_SIMPLE_TYPE[resp_string]

        raise InvalidRESPType.new(expected: bytesize, got: underlying_string.bytesize) if underlying_string.bytesize != bytesize

        underlying_string
      end
    end

    RESPArray = Struct.new(:underlying_array, :callback) do
      def encode
        "*#{underlying_array.length}\r\n" << underlying_array.map { callback[_1] }.join
      end

      def decode
        array_size = underlying_array[0].to_i
        resp_array = underlying_array
          .partition(/(\r\n|\r|\n)+/)[-1]
          .split(/(?=#{RESP::TYPES})/)

        raise InvalidRESPType.new(expected: array_size, got: resp_array.size) if resp_array.size != array_size

        resp_array.map { callback[_1] }
      end
    end

    NullArrayInstance = Object.new.tap do |obj|
      def obj.decode
        [nil]
      end
    end

    NullBulkStringInstance = Object.new.tap do |obj|
      def obj.decode
        nil
      end

      def obj.encode
        NULL_BULK_STRING
      end
    end
  end
end
