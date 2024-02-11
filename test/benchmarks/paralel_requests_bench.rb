require 'test_helper'
require "minitest/benchmark"
require 'support/test_server_helper'

require 'benchmark'

describe 'Server Bench' do
  bench_range { bench_exp(1, 1)}

  before { start_redis_server }
  after { stop_redis_server }

  let(:req_number) {  50_000 }
  let(:hash_to_store) { req_number.times.map { |i| ["key#{i}", "value#{i}"] }.to_h }

  describe 'requests single thread' do
    bench_performance_linear '20_000 SET commands', 30 do |n|
      puts(Benchmark.measure {
        hash_to_store.each do |k, v|
          send_command("SET #{k} #{v}")
        end })

        assert_equal req_number, send_command("DBSIZE").to_i
    end
  end

  describe 'paralel requests from 10 Ractor instances' do
    let(:commands) { hash_to_store.map { |k, v| "SET #{k} #{v}" } }

    bench_performance_linear '5_000x10 SET command', 15.555 do |n|
      r = send_parallel_commands(commands, limit: 10)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end
end
