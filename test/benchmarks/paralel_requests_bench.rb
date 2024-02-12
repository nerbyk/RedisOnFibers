require 'test_helper'
require "minitest/benchmark"
require 'support/test_server_helper'

require 'benchmark'

describe 'Server' do
  # bench_range { bench_exp(1, 1)}
  BENCHMARK_LOG = <<~LOG
  \n\n
  =========== Benchmark Results =============
  %{example}
  Time (min) Time (avg) Time (max) Total Time
  %{measure}
  ===========================================
  LOG

  def benchmark_example(&block)
    measure = Benchmark.measure(&block)

    puts BENCHMARK_LOG % {
      measure:, example: name
    }
  end

  before { start_redis_server }
  around { |&block| benchmark_example { super(&block) } }
  after { stop_redis_server }

  let(:req_number) {  1_000_000 }
  let(:hash_to_store) { req_number.times.map { |i| ["key#{i}", "value#{i}"] }.to_h }

  describe 'requests single thread' do
    # bench_performance_linear '20_000 SET commands', 30 do |n|
    it "processes :req_number SET commands one by one" do
      hash_to_store.each do |k, v|
        send_command("SET #{k} #{v}")
      end

      assert_equal req_number, send_command("DBSIZE").to_i
    end
  end

  describe 'paralel requests from 10 Ractor instances' do
    let(:commands) { hash_to_store.map { |k, v| "SET #{k} #{v}" } }

    it 'processec :req_number SET commands in paralel' do 
      r = send_parallel_commands(commands, limit: 10)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end
end
