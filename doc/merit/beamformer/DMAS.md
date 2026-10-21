# merit.beamformer.DMAS

Delay-multiply-and-sum beamformer

Package: `merit.beamformer`

## Syntax

```text
image_ = merit.beamformer.DMAS()
```

## Description

`image_ = merit.beamformer.DMAS()` returns the delay-multiply-and-sum beamformer as a function handle for [merit.beamform](../beamform.md). Instead of summing the delayed channels, it sums the products of all pairs of different channels, which emphasises responses that are present in many channels.

## Examples

### Image part of the domain with delay-multiply-and-sum

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

points = merit.domain.hemisphere(7e-2, resolution=1e-2);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DMAS));
```

With 96 channels the beamformer forms 4560 products for each sample and point, so it is much slower than delay-and-sum; a grid spacing of 1 cm keeps this example short.

## Output Arguments

### `image_` — beamformer function

function handle

`values = image_(delayed)` takes an N x C x P array of delayed signals and returns a P x 1 vector.

## Algorithms

The intended result for the delayed signals x(n, c, p) is

```text
y(n, p)   = sum over all pairs i < j of x(n, i, p) * x(n, j, p)
values(p) = sum over n of y(n, p)^2
```

The pairs are processed in blocks of C + 1 consecutive pairs that start every C pairs, so consecutive blocks overlap by one pair.

## Tips

- Because of the overlapping blocks, one pair in every C is added twice. With three channels or fewer there is only one block and the result is exact; with more channels it differs from the formula above. For random signals of four channels at two points, the function returned 17.3 and 185.6 where the formula gives 25.6 and 118.1.
- For complex frequency-domain signals, the products and squares are complex; take `abs` of the image.

## See Also

[merit.beamformer.DAS](DAS.md) | [merit.beamformer.CDAS](CDAS.md) | [merit.beamform](../beamform.md)
