# merit.test.time_this

Measure the time taken by one call of a function

Package: `merit.test`

## Syntax

```text
execution_time = merit.test.time_this(function_)
```

## Description

`execution_time = merit.test.time_this(function_)` calls `function_` once without arguments and returns the elapsed time in seconds, measured with `tic` and `toc`.

## Examples

### Time the delays of a frequency-domain scan

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

points = merit.domain.hemisphere(7e-2, pixel_dim=50);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
d = delays(points);

t_double = merit.test.time_this(@() merit.process.delay(signals, d, frequencies));
t_single = merit.test.time_this(@() merit.process.delay(single(signals), single(d), single(frequencies)));
```

## Input Arguments

### `function_` — function to time

function handle

A function that takes no inputs and returns at least one output.

## Output Arguments

### `execution_time` — elapsed time in seconds

scalar

## Tips

- The function is called as `[~] = function_()`, so a function without outputs causes an error. Wrap such a function in one that returns a value.
- A single call is affected by the first-call overhead of MATLAB and by other activity on the computer. For a reliable comparison, repeat the measurement or use `timeit`.
- [merit.test.profile_this](profile_this.md) reports the time spent in each called function, at the cost of profiling overhead.

## See Also

[merit.test.profile_this](profile_this.md)
