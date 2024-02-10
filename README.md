# RedisOnFibers

This is a playground server built for experimenting with Ruby 3+ non-blocking fibers. It provides a simple TCP server that can handle multiple connections concurrently using fibers for non-blocking I/O operations.

The server utilizes a fiber pool to efficiently manage concurrent connections.

## Benchmarking

```sh
bundle exec rake test:benchmark
```

## Benchmark Results

The benchmark involves 50,000 SET requests.

| Description                                     | Time (min) | Time (avg) | Time (max) | Total Time |
|-------------------------------------------------|------------|------------|------------|------------|
| Parallel Requests from 10 Ractor Instances      | 6.578125   | 20.531250  | 27.109375  | 16.792934  |
| Sequential Requests                             | 4.828125   | 12.968750  | 17.796875  | 26.184918  |

## Usage

```sh
bin/server
```

```sh
bin/client
```
