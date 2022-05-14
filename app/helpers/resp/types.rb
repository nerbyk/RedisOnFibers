module RESP
  module Types
    class InvalidRESPType < StandardError; end

    RESPInteger = Struct.new(:underlying_integer) do
      def generate
        ":#{underlying_integer}\r\n"
      end

      def parse
        underlying_integer.to_i
      end
    end

    RESPSimpleString = Struct.new(:underlying_string) do
      def generate
        "+#{underlying_string}\r\n"
      end

      def parse
        underlying_string
      end
    end

    RESPSimpleError = Struct.new(:underlying_error) do
      def generate
        "-#{underlying_error}\r\n"
      end

      def parse
        underlying_error
      end
    end

    RESPBulkString = Struct.new(:underlying_string, :bytesize) do
      def generate
        "$#{underlying_string.bytesize}\r\n#{underlying_string}\r\n"
      end

      def parse
        raise InvalidRESPType, 'Ivalid type size' if underlying_string.bytesize != bytesize

        underlying_string
      end
    end

    NullBulkStringInstance = Object.new.tap do |obj|
      NULL_BULK_STRING = "$-1\r\n".freeze
      def obj.parse
        nil
      end

      def obj.generate
        NULL_BULK_STRING
      end
    end

    RESPArray = Struct.new(:underlying_array, :elements_count) do
      def generate
        "*#{underlying_array.length}\r\n" << underlying_array.map { |element| RESP.generate(element) }.join
      end

      def parse
        raise InvalidRESPType, 'Ivalid type size' if underlying_array.size != elements_count

        underlying_array.map { |el|
          RESP.parse(el)
        }
      end
    end

    NullArrayInstance = Object.new.tap do |obj|
      NULL_ARRAY_STRING = "*-1\r\n".freeze
      def obj.parse
        [nil]
      end
    end
  end
end
