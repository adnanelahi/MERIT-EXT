# merit.beamformer.DAS

Delay-and-sum beamformer

Package: `merit.beamformer`

## Syntax

```text
image_ = merit.beamformer.DAS()
```

## Description

`image_ = merit.beamformer.DAS()` returns the delay-and-sum beamformer as a function handle for [merit.beamform](../beamform.md). `image_(delayed)` sums the delayed signals over the channels, squares the sum and sums the squares over the samples, giving one value for each point.

## Examples

### Image with delay-and-sum

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

points = merit.domain.hemisphere(7e-2, resolution=5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));
```

### Apply the beamformer to an array directly

```matlab
das = merit.beamformer.DAS();
delayed = cat(3, [1 1; 2 2], [1 -1; 2 -2]);
das(delayed)
```

The two points give 20 and 0: the channels add coherently at the first point and cancel at the second.

## Output Arguments

### `image_` — beamformer function

function handle

`values = image_(delayed)` takes an N x C x P array of delayed signals (samples x channels x points) and returns a P x 1 vector.

## Algorithms

For the delayed signals x(n, c, p),

```text
values(p) = sum over n of ( sum over c of x(n, c, p) )^2
```

## Tips

- For complex frequency-domain signals, the square is the complex square, not the squared magnitude; take `abs` of the image.

## See Also

[merit.beamformer.CDAS](CDAS.md) | [merit.beamformer.DMAS](DMAS.md) | [merit.beamform](../beamform.md)
