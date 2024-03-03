# RedisOnFibers

This is a playground server built for experimenting with Ruby 3+ non-blocking fibers. It provides a simple TCP server that can handle multiple connections concurrently using fibers for non-blocking I/O operations.

The server utilizes a fiber pool to efficiently manage concurrent connections.

## Benchmarking

```sh
bundle exec rake test:benchmarks
```

## Benchmark Results (On Intel Core i5-12400F)

### Sequential SET Commands (100,000)

| Client     | Time (min) | Time (avg) | Time (max) | Total Time |
|------------|------------|------------|------------|------------|
| Single Thread  | 2.015625s  | 1.468750s  | 7.234375s  | 6.553422s  |
| 5 Ractors (20,000 each) | 1.359375s  | 2.203125s  | 6.531250s  | 3.492113s  |
| 10 Forks (10,000 each)  | 0.109375s  | 0.921875s  | 15.703125s | 4.244236s  |


### Sequential SET Commands (500,000)

| Client     | Time (min) | Time (avg) | Time (max) | Total Time |
|------------|------------|------------|------------|------------|
| Single Thread  | 7.859375s  | 7.359375s  | 33.968750s | 29.932314s |
| 5 Ractors (100,000 each) | 9.843750s  | 8.734375s  | 30.828125s | 15.597305s |
| 10 Forks (50,000 each)   | 0.531250s   | 0.906250s  | 30.875000s | 13.810783s |

### Sequential SET Commands (1,000,000)

| Client     | Time (min) | Time (avg) | Time (max) | Total Time |
|------------|------------|------------|------------|------------|
| Single Thread  | 18.218750s | 15.578125s | 70.656250s | 62.121204s |
| 5 Ractors (200,000 each) | 18.921875s | 16.828125s | 64.078125s | 34.095834s |
| 10 Forks (100,000 each)   | 1.328125s  | 0.703125s  | 61.812500s | 29.925912s |

### Benchmark for Single Threaded 100,000 SET Commands with & w/o Logging

| Client           | Time (min) | Time (avg) | Time (max) | Total Time |
|------------------|------------|------------|------------|------------|
| w\o logging      | 2.015625s  | 1.468750s  | 7.234375s  | 6.553422s  |
| w/ sync logging  | 3.843750   | 3.640625   | 16.578125  | 12.338142  |
| w/ async logging | 2.515625   | 1.515625   | 10.859375  | 8.540589   |

## Usage

```sh
bin/server
```

```sh
bin/client
```
