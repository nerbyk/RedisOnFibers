# frozen_string_literal: true

require 'test_helper'
require 'socket'
require 'server'
require 'support/test_server_helper'

describe Server do
  before { start_redis_server }
  after { stop_redis_server }

  describe 'commands processing' do
    it 'should respond to PING command' do
      response = send_command("PING")
      assert_equal "PONG", response
    end

    it 'should respond to ECHO command' do
      response = send_command('ECHO Hello')
      assert_equal "Hello", response
    end

    it 'should set and get values correctly' do
      set = send_command('SET key1 value1')
      assert_equal "OK", set

      get = send_command('GET key1')
      assert_equal 'value1', get
    end

    it 'should return nil for non existing key' do
      response = send_command('GET key2')
      assert_equal '', response
    end
  end

  describe 'multiple commands processing' do
    it 'should process multiple commands in one request' do
      response = send_commmands(['SET key1 value1', 'GET key1'])
      assert_equal ['OK', 'value1'], response
    end
  end

  describe 'multiple clients processing' do
    it 'should process multiple clients' do
      commands = 5.times.map { "SET key#{_1} value#{_1}" }

      send_commands_with_forks(commands)

      assert_equal ['value0', 'value1', 'value2', 'value3', 'value4'], send_commmands(5.times.map { |i| "GET key#{i}" })
    end
  end
end
