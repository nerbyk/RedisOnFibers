# RedisOnFibers

This is a playground server built for experimenting with Ruby 3+ non-blocking fibers. It provides a simple TCP server that can handle multiple connections concurrently using fibers for non-blocking I/O operations.

The server utilizes a fiber pool to efficiently manage concurrent connections.

## Benchmarking

```sh
bundle exec rake test:benchmarks
```

## Benchmark Results (On Intel Core i5-12400F)

### Sequential SET Commands (100,000)

| Description            | Time (min) | Time (avg) | Time (max) | Total Time |
|------------------------|------------|------------|------------|------------|
| Single Thread          | 2.015625   | 1.468750   | 7.234375   | 6.553422   |
| 5 Ractors              | 1.359375   | 2.203125   | 6.531250   | 3.492113   |
| 10 Forks               | 0.531250   | 0.906250   | 30.875000  | 13.810783  |

### Sequential SET Commands (500,000)

| Description            | Time (min) | Time (avg) | Time (max) | Total Time |
|------------------------|------------|------------|------------|------------|
| Single Thread          | 7.859375   | 7.359375   | 33.968750  | 29.932314  |
| 5 Ractors              | 9.843750   | 8.734375   | 30.828125  | 15.597305  |
| 10 Forks               | 0.531250   | 0.906250   | 30.875000  | 13.810783  |

### Sequential SET Commands (1,000,000)

| Description            | Time (min) | Time (avg) | Time (max) | Total Time |
|------------------------|------------|------------|------------|------------|
| Single Thread          | 18.218750  | 15.578125  | 70.656250  | 62.121204  |
| 5 Ractors              | 18.921875  | 16.828125  | 64.078125  | 34.095834  |
| 10 Forks               | 1.328125   | 0.703125   | 61.812500  | 29.925912  |


## Usage

```sh
bin/server
```

```sh
bin/client
```
