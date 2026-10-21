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
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));
size(img)
```

`img` is a 47185 x 1 vector with one value per point.

### Compare two permittivities in one call

```matlab
delays9 = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 9);
imgs = abs(merit.beamform(signals, frequencies, points, {delays, delays9}, merit.beamformers.DAS));
size(imgs)
```

With a cell array of two delay functions, `imgs` is 47185 x 2: one column for each delay function.

### Image time-domain signals with a window

```matlab
time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
img_td = merit.beamform(td, time_axis, points, delays, merit.beamformers.DAS, ...
    'window', merit.beamform.windows.rectangular(100));
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

One point per row, with coordinates in metres, as returned by [merit.domain.hemisphere](domain/hemisphere.md) or [merit.beamform.imaging_domain](beamform/imaging_domain.md).

### `delay` — delay function

function handle | cell array of function handles

A function that takes a block of rows of `points` and returns the delay of every channel to each of those points as a 1 x C x P array, as created by [merit.beamform.get_delays](beamform/get_delays.md). With a cell array of D functions, the image is calculated once for each function.

### `image_` — beamformer

function handle

A function that takes the delayed signals, an N x C x P array, and returns one value per point, as created by [merit.beamformers.DAS](beamformers/DAS.md), [merit.beamformers.CDAS](beamformers/CDAS.md) or [merit.beamformers.DMAS](beamformers/DMAS.md).

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `max_memory` | positive number | `1e9` | Approximate number of bytes of delayed signals held in memory at once. The points are processed in blocks of this size. |
| `gpu` | logical | `false` | Process the signals on the GPU if one is available and has room for them. |
| `window` | function handle | `@(a) a` | Function applied to the delayed signals before the beamformer, such as [merit.beamform.windows.rectangular](beamform/windows/rectangular.md). |

## Output Arguments

### `img` — image values

P x D array

One value for each point and each delay function. With the beamformers of MERIT, the values are complex for frequency-domain signals and real for time-domain signals.

## Algorithms

The points are divided into blocks of `floor(max_memory / (numel(signals) * bytes))` points, where `bytes` is 8 for real and 16 for complex values, halved for `single` arrays. For each block and each delay function, the function computes

```text
img(block, d) = image_(window(merit.process.delay(signals, delay{d}(points(block, :)), axis_)))
```

With `'gpu', true`, the signals and points are copied to the GPU if its free memory exceeds the size of the signals, and the block size is set from a quarter of the free GPU memory. If no GPU can be used, the calculation continues on the CPU without a message. The GPU is reset after the calculation.

## Tips

- The beamformers of MERIT square complex sums without taking their magnitude, so take `abs` of a frequency-domain image before displaying or comparing it.
- Time-domain signals are delayed by whole samples and the vacated samples are set to `NaN`. Use a window that keeps only samples that are valid after the largest delay; otherwise every value of the image is `NaN`.
- The function header declares a second output, `sigs`, that is never assigned. Requesting two outputs causes an error.
- The `'gpu'` option needs the Parallel Computing Toolbox.

## See Also

[merit.beamform.get_delays](beamform/get_delays.md) | [merit.beamformers.DAS](beamformers/DAS.md) | [merit.process.delay](process/delay.md) | [merit.domain.hemisphere](domain/hemisphere.md)
