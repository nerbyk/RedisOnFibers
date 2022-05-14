module RESP
  module Serializers
    SimpleStringSerializer = -> (resp_string) {
      resp_string.tap {
        _1.chomp!
        _1.tr!("\r\n", '')
        _1.gsub!(/ {2,}/, ' ')
      }
    }

    ArraySerializer = -> (resp_string) {
      (resp_type_size, resp_string) = sized_resp(resp_string)

      [resp_string.scan(/[^\r\n]*\r\n/), resp_type_size]
    }

    BulkStringSerializer = -> (resp_string) {
      (resp_type_size, resp_string) = sized_resp(resp_string)
      [SimpleStringSerializer[resp_string], resp_type_size]
    }

    private

    module_function

    def sized_resp(resp_string)
      partitioned = resp_string.partition(/(\r\n|\r|\n)+/)

      [partitioned[0][1..].to_i, partitioned[-1]]
    end
  end
end
