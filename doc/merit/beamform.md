# merit.beamform

Form an image by delaying the signals for each imaging point and combining them with a beamformer

Package: `merit`

## Syntax

```text
img = merit.beamform(signals, axis_, points, delay, image_)
img = merit.beamform(___, Name, Value)
```

## Description

`img = merit.beamform(signals, axis_, points, delay, image_)` calculates one image value for every point in `points`. For each point, every channel of `signals` is delayed by the time returned by `delay` for that channel and point, and the beamformer `image_` combines the delayed channels into one value.

`img = merit.beamform(___, Name, Value)` sets the memory limit, a window applied to the delayed signals, or the use of a GPU.

## Examples

### Image a rotation-subtracted scan with delay-and-sum

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));
```

`img` is a column vector with one value per point.

### Compare two permittivities in one call

```matlab
delays9 = merit.get_delay(channel_names, antenna_locations, relative_permittivity=9);
imgs = abs(merit.beamform(signals, frequencies, points, {delays, delays9}, merit.beamformer.DAS));
```

With a cell array of two delay functions, `imgs` has two columns, one for each delay function.

### Image time-domain signals with a window

```matlab
time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
img_td = merit.beamform(td, time_axis, points, delays, merit.beamformer.DAS, ...
    window=merit.domain.windows.rectangular(100));
```

## Input Arguments

### `signals` — signals of all channels

N x C array

N samples of C channels. Complex signals are treated as frequency-domain signals and real signals as time-domain signals (see [merit.process.delay](process/delay.md)). The arrays may be `single`, which halves the memory used.

### `axis_` — sample axis

vector of length N

The frequency of each sample in hertz for frequency-domain signals, or the time of each sample in seconds for time-domain signals. A time axis must have a constant step.

### `points` — imaging points

P x D array

One point per row, with coordinates in metres, as returned by [merit.domain.hemisphere](domain/hemisphere.md) or [merit.domain.get_points](domain/get_points.md).

### `delay` — delay function

function handle | cell array of function handles

A function that takes a block of rows of `points` and returns the delay of every channel to each of those points as a 1 x C x P array, as created by [merit.get_delay](get_delay.md). With a cell array of D functions, the image is calculated once for each function.

### `image_` — beamformer

function handle

A function that takes the delayed signals, an N x C x P array, and returns one value per point, as created by [merit.beamformer.DAS](beamformer/DAS.md), [merit.beamformer.CDAS](beamformer/CDAS.md) or [merit.beamformer.DMAS](beamformer/DMAS.md).

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `max_memory` | number | `1e9` | Approximate number of bytes of delayed signals held in memory at once. The points are processed in blocks of this size. |
| `gpu` | logical or numeric | `false` | Process the signals on the GPU if one is available and has room for them. |
| `window` | function handle | `@(a) a` | Function applied to the delayed signals before the beamformer, such as [merit.domain.windows.rectangular](domain/windows/rectangular.md). |

## Output Arguments

### `img` — image values

P x D array

One value for each point and each delay function. With the beamformers of MERIT, the values are complex for frequency-domain signals and real for time-domain signals.

## Algorithms

The points are divided into blocks of `floor(max_memory / (numel(signals) * bytes))` points, where `bytes` is 8 for real and 16 for complex values, halved for `single` arrays. For each block and each delay function, the function computes

```text
img(block, d) = image_(window(merit.process.delay(signals, delay{d}(points(block, :)), axis_)))
```

With `gpu=true`, the signals and points are copied to the GPU if its free memory exceeds the size of the signals, and the block size is set from a quarter of the free GPU memory. If no GPU can be used, the calculation continues on the CPU without a message. The GPU is reset after the calculation.

## Tips

- The beamformers of MERIT square complex sums without taking their magnitude, so take `abs` of a frequency-domain image before displaying or comparing it.
- Time-domain signals are delayed by whole samples and the vacated samples are set to `NaN`. Use a window that keeps only samples that are valid after the largest delay; otherwise every value of the image is `NaN`.
- The function header declares a second output, `sigs`, that is never assigned. Requesting two outputs causes an error.
- The `gpu` option needs the Parallel Computing Toolbox.

## See Also

[merit.get_delay](get_delay.md) | [merit.beamformer.DAS](beamformer/DAS.md) | [merit.process.delay](process/delay.md) | [merit.domain.hemisphere](domain/hemisphere.md)
