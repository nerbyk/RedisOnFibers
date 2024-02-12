require 'test_helper'
require "minitest/benchmark"
require 'support/test_server_helper'

require 'benchmark'

describe 'Server' do
  # bench_range { bench_exp(1, 1)}
  BENCHMARK_LOG = <<~LOG
  \n\n
  =========== Benchmark Results =============
  %{example} - %{req_number}
  Time (min) Time (avg) Time (max) Total Time
  %{measure}
  ===========================================
  LOG

  def benchmark_example(&block)
    measure = Benchmark.measure(&block)

    puts BENCHMARK_LOG % {
      measure:, req_number:, example: name
    }
  end

  before { start_redis_server }
  around { |&block| benchmark_example { super(&block) } }
  after { stop_redis_server }

  let(:req_number) {  100_000 }
  let(:hash_to_store) { req_number.times.map { |i| ["key#{i}", "value#{i}"] }.to_h }
  let(:commands) { hash_to_store.map { |k, v| "SET #{k} #{v}" } }

  describe "100_000 SET commands" do
    it "processes SET commands one by one" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'processes SET commands from 10 forks' do
      send_commands_with_forks(commands, limit: 10)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "processes SET commands from 5 ractors" do 
      r = send_commands_with_ractors(commands, limit: 5)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end

  describe "500_000 SET commands" do
    let(:req_number) {  500_000 }

    it "processes SET commands one by one" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'processes SET commands from 10 forks' do
      send_commands_with_forks(commands, limit: 10)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "processes SET commands from 5 ractors" do 
      r = send_commands_with_ractors(commands, limit: 5)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end

  describe "1_000_000 SET commands" do
    let(:req_number) {  1_000_000 }

    it "processes SET commands one by one" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'processes SET commands from 10 forks' do
      send_commands_with_forks(commands, limit: 5)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "processes SET commands from 5 ractors" do 
      r = send_commands_with_ractors(commands, limit: 5)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end
end
