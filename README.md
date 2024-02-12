# RedisOnFibers

This is a playground server built for experimenting with Ruby 3+ non-blocking fibers. It provides a simple TCP server that can handle multiple connections concurrently using fibers for non-blocking I/O operations.

The server utilizes a fiber pool to efficiently manage concurrent connections.

## Benchmarking

```sh
bundle exec rake test:benchmarks
```

## Benchmark Results

### Parallel SET Commands under 10 Ractors

| Description                                | Time (min) | Time (avg) | Time (max) | Total Time |
|--------------------------------------------|------------|------------|------------|------------|
| 500,000 SET Commands                       | 8.328125   | 9.140625   | 30.625000  | 15.368673  |
| 1,000,000 SET Commands                     | 23.343750  | 19.000000  | 68.671875  | 35.260370  |

### Single Thread Sequential SET Commands

| Description            | Time (min) | Time (avg) | Time (max) | Total Time |
|------------------------|------------|------------|------------|------------|
| 500,000 SET Commands   | 7.734375   | 7.937500   | 34.484375  | 29.627424  |
| 1,000,000 SET Commands | 14.328125  | 15.593750  | 68.703125  | 58.686087  |

## Usage

```sh
bin/server
```

```sh
bin/client
```
