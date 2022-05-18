require 'test_helper'
require './app/helpers/resp'

describe RESP do
  let(:described_module) { RESP }

  describe '#parse' do
    it 'returns a simple string' do
      assert_equal 'OK', described_module.parse("+OK\r\n")
    end

    it 'returns a simple integer' do
      assert_equal 1, described_module.parse(":1\r\n")
    end

    it 'returns a simple bulk string' do
      assert_equal 'OK', described_module.parse("$2\r\nOK\r\n")
    end

    it 'returns null bulk string' do
      assert_nil described_module.parse("$-1\r\n")
    end

    it 'returns a simple array' do
      assert_equal ['OK'], described_module.parse("*1\r\n+OK\r\n")
    end

    it 'returns a nested array with null bulk string' do
      assert_equal [nil], described_module.parse("*1\r\n$-1\r\n")
    end

    it 'return a nested array for redis ECHO with bulk types' do
      assert_equal ['ECHO', 'simple', 'foobar'], described_module.parse("*3\r\n$4\r\nECHO\r\n+simple\r\n$6\r\nfoo\r\nbar\r\n")
    end
  end

  describe '#generate' do
    it 'generates a simple string' do
      assert_equal "+OK\r\n", described_module.generate('OK')
    end

    it 'generates a simple integer' do
      assert_equal ":1\r\n", described_module.generate(1)
    end

    it 'generates a simple bulk string' do
      assert_equal "$2\r\nOK\r\n", described_module.generate('OK', with_bytesize: true)
    end

    it 'generates a simple array' do
      assert_equal "*1\r\n+OK\r\n", described_module.generate(['OK'])
    end

    it 'generates a nested array with diffrent types' do
      assert_equal "*3\r\n+foo\r\n:1337\r\n+bar\r\n", described_module.generate(['foo', 1337, 'bar'])
    end

    it 'generates a nested array with null bulk string' do
      assert_equal "*1\r\n$-1\r\n", described_module.generate([nil])
    end
  end
end
