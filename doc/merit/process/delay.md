# merit.process.delay

Delay signals in the time or the frequency domain

Package: `merit.process`

## Syntax

```text
delayed = merit.process.delay(signals, delays, axis_)
delayed = merit.process.delay(signals, delays, axis_, padding)
delayed = merit.process.delay(signals, sample_delays)
delayed = merit.process.delay(signals, sample_delays, padding)
```

## Description

`delayed = merit.process.delay(signals, delays, axis_)` delays each channel of `signals` by the corresponding time in `delays`, in seconds. Complex signals are treated as frequency-domain signals and multiplied by a phase ramp; `axis_` gives the frequency of each sample. Real signals are treated as time-domain signals and shifted by the nearest whole number of samples; `axis_` gives the time of each sample.

`delayed = merit.process.delay(signals, delays, axis_, padding)` sets the function used to fill the samples vacated by a time-domain shift. The default, `@nan`, fills them with `NaN`.

`delayed = merit.process.delay(signals, sample_delays)` shifts real signals by integer numbers of samples.

`delayed = merit.process.delay(signals, sample_delays, padding)` does the same with a padding function.

## Examples

### Shift two time-domain channels by whole samples

```matlab
x = [1 2 3 4 5; 10 20 30 40 50]';
merit.process.delay(x, [1 -2])
merit.process.delay(x, [1 -2], @zeros)
```

The first channel is delayed by one sample and the second advanced by two. The vacated samples are `NaN` in the first result and zero in the second.

### Delay with a time axis

```matlab
merit.process.delay(x, [1e-11 -2e-11], 0:1e-11:4e-11)
```

With a sample interval of 10 ps, this gives the same result as the first call above.

### Delay frequency-domain signals for one imaging point

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
focused = merit.process.delay(signals, delays([0.015 0 0.035]), frequencies);
size(focused)
```

## Input Arguments

### `signals` — signals to delay

N x C array | N x C x P array

N samples of C channels. Complex arrays are delayed in the frequency domain and real arrays in the time domain.

### `delays` — delay of each channel in seconds

1 x C array | 1 x C x P array

Positive values delay a signal and negative values advance it. A 1 x C x P array delays the signals once for each of P points; the signals are then replicated along the third dimension.

### `axis_` — sample axis

vector of length N

Frequencies in hertz for complex signals, or times in seconds for real signals. A time axis must increase with a constant step.

### `sample_delays` — delay of each channel in samples

integer array, 1 x C or 1 x C x P

### `padding` — padding function

function handle (default `@nan`)

A function with the calling form of `nan` and `zeros`, `padding(sz, 'like', signals)`, that returns the initial contents of the delayed array.

## Output Arguments

### `delayed` — delayed signals

array of the size of `signals` after replication

## Algorithms

In the frequency domain, each sample is multiplied by exp(-j2π f τ), where f is its frequency and τ the delay of its channel. In the time domain, the delay is rounded to the nearest sample and each channel is shifted, so a delay of τ moves sample n to sample n + round(τ / Δt).

## Tips

- The domain is chosen by `isreal`, so frequency-domain data whose values are all real are shifted as time-domain data.
- A padding function has an effect only in the time domain. With complex signals and four arguments, the signals are returned unchanged and not delayed.
- With real signals and an axis whose length differs from the number of samples, no output is assigned and MATLAB reports an error.

## See Also

[merit.beamform](../beamform.md) | [merit.get_delay](../get_delay.md) | [merit.domain.windows.rectangular](../domain/windows/rectangular.md)
