# merit.test.profile_this

Profile one call of a function

Package: `merit.test`

## Syntax

```text
profile_info = merit.test.profile_this(function_)
```

## Description

`profile_info = merit.test.profile_this(function_)` calls `function_` once without arguments with the MATLAB profiler switched on and returns the profiler's results. The results include the number of calls and the time spent in every function called, which shows where the time goes.

## Examples

### Compare the delays in double and single precision

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

points = merit.domain.hemisphere(7e-2, pixel_dim=50);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
d = delays(points);

info_double = merit.test.profile_this(@() merit.process.delay(signals, d, frequencies));
info_single = merit.test.profile_this(@() merit.process.delay(single(signals), single(d), single(frequencies)));
[info_double.FunctionTable(1).TotalTime, info_single.FunctionTable(1).TotalTime]
```

This is the comparison made by the script `merit.example_scripts.measure_performance`, which also lists the functions called as a table.

## Input Arguments

### `function_` — function to profile

function handle

A function that takes no inputs and returns at least one output.

## Output Arguments

### `profile_info` — profiler results

structure

The output of `profile('info')`. Its field `FunctionTable` has one element per function called, with the fields `FunctionName`, `NumCalls`, `TotalTime` and `Children`, among others.

## Tips

- The profiler slows the code down, so the times are larger than without it. Use [merit.test.time_this](time_this.md) to measure the time alone.
- The profiler's data are cleared after the call, which also clears any profiling session started before.

## See Also

[merit.test.time_this](time_this.md)
