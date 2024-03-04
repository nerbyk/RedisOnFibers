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

  let(:req_number) {  100_000 }
  let(:hash_to_store) { req_number.times.map { |i| ["key#{i}", "value#{i}"] }.to_h }
  let(:commands) { hash_to_store.map { |k, v| "SET #{k} #{v}" } }
  let(:workers) { 5 }

  before do 
    start_redis_server 
    preload_commands
    puts "Starting benchmark..."
  end 

  after { stop_redis_server }
  around { |&block| benchmark_example { super(&block) } }

  def benchmark_example(&block)
    Benchmark.measure(&block).tap do |measure|
      puts BENCHMARK_LOG % {
        measure:, req_number:, example: name
      }
    end
  end

  def preload_commands(start_time = Time.now)
    puts "Preloading SET commands..."
    commands
    puts "Preloaded #{req_number} SET commands in #{Time.now - start_time} seconds"
  end

  describe "100_000" do
    it "seq" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'forked' do
      send_commands_with_forks(commands, limit: workers)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "ractored" do 
      r = send_commands_with_ractors(commands, limit: workers)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end

  describe "500_000" do
    let(:req_number) {  500_000 }

    it "seq" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'forked' do
      send_commands_with_forks(commands, limit: workers)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "ractored" do 
      r = send_commands_with_ractors(commands, limit: workers)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end

  describe "1_000_000" do
    let(:req_number) {  1_000_000 }

    it "seq" do
      send_commmands(commands)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it 'forked' do
      send_commands_with_forks(commands, limit: workers)

      assert_equal req_number, send_command("DBSIZE").to_i
    end

    it "ractored" do 
      r = send_commands_with_ractors(commands, limit: workers)

      assert_equal commands.size, r.sum { |res| res.flatten.size }
    end
  end

  describe "logging" do
    describe "sync" do
      before { ENV['DEBUG'] = 'true' }
      after { ENV.delete('DEBUG') }

      it("seq") { send_commmands(commands) }
    end

    describe "async" do
      before { ENV.delete('DEBUG') }

      it("seq") { send_commmands(commands) }
    end
  end
end
