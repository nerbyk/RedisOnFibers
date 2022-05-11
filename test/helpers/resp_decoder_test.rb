# frozen_string_literal: true

require 'test_helper'
require './app/helpers/resp_decoder'

describe RespDecoder do
  let(:described_class) { RespDecoder }

  describe '#decode' do
    it 'returns a simple string' do
      assert_equal 'OK', described_class.decode('+OK')
    end

    it 'decode a simple integer' do
      assert_equal 1, described_class.decode(':1')
    end

    it 'decode a simple bulk string' do
      assert_equal 'OK', described_class.decode("$2\r\nOK")
    end

    it 'decodes null bulk string' do
      assert_equal nil, described_class.decode("$-1\r\n")
    end

    it 'decode a simple array' do
      assert_equal ['OK'], described_class.decode("*1\r\n+OK")
    end

    it 'decodes a nested array with diffrent types' do
      assert_equal ['foo', 3, 'bar'], described_class.decode("*3\r\n+foo\r\n:1337\r\n+bar")
    end
  end
end
