# merit.beamform.windows.rectangular

Create a window that keeps the first samples of the delayed signals

Package: `merit.beamform.windows`

## Syntax

```text
window = merit.beamform.windows.rectangular(window_length)
```

## Description

`window = merit.beamform.windows.rectangular(window_length)` returns a function handle. `window(signals)` keeps the first `window_length` samples of each channel and of each point of `signals` and discards the rest. Pass it to [merit.beamform](../../beamform.md) with the name-value argument `'window'`.

## Examples

### Keep the first three samples

```matlab
window = merit.beamform.windows.rectangular(3);
window(reshape(1:10, 5, 2))
```

The result is `[1 6; 2 7; 3 8]`.

### Restrict time-domain beamforming to the first nanosecond

```matlab
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
points = merit.domain.hemisphere('radius', 7e-2, 'resolution', 5e-3);
delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
img = merit.beamform(td, time_axis, points, delays, merit.beamformers.DAS, ...
    'window', merit.beamform.windows.rectangular(100));
any(isnan(img))
```

With 100 samples of 10 ps, the beamformer uses the first nanosecond after the delay, and no image value is `NaN`.

## Input Arguments

### `window_length` — number of samples to keep

positive integer

Must not exceed the number of samples of the signals to which the window is applied.

## Output Arguments

### `window` — window function

function handle

Takes an N x C x ... array and returns its first `window_length` rows, with the other dimensions unchanged.

## Tips

- In the time domain, [merit.process.delay](../../process/delay.md) fills the samples vacated by the delay with `NaN`. The delays from [merit.beamform.get_delays](../get_delays.md) are negative, so the `NaN` values occupy the end of each signal. Choose `window_length` no larger than the number of samples minus the largest delay in samples.
- In the frequency domain, the window selects the lowest `window_length` frequencies.

## See Also

[merit.beamform](../../beamform.md) | [merit.process.delay](../../process/delay.md)
