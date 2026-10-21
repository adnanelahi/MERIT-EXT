# merit.beamformer.CDAS

Delay-and-sum beamformer weighted by a coherence factor

Package: `merit.beamformer`

## Syntax

```text
image_ = merit.beamformer.CDAS()
```

## Description

`image_ = merit.beamformer.CDAS()` returns a beamformer for [merit.beamform](../beamform.md) that multiplies the delay-and-sum value of each point by a coherence factor. The factor is large where the delayed channels agree and small where they do not, which suppresses clutter.

## Examples

### Compare delay-and-sum with its coherence-weighted form

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

points = merit.domain.hemisphere(7e-2, resolution=5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img_das = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));
img_cdas = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.CDAS));
```

## Output Arguments

### `image_` — beamformer function

function handle

`values = image_(delayed)` takes an N x C x P array of delayed signals and returns a P x 1 vector.

## Algorithms

For the delayed signals x(n, c, p),

```text
E(p)      = sum over n of ( sum over c of x(n, c, p) )^2
F(p)      = E(p) / ( sum over n and c of x(n, c, p)^2 )
values(p) = E(p) * F(p)
```

E is the delay-and-sum value. The coherence factor F is not divided by the number of channels, so it ranges from 0 to C rather than from 0 to 1.

## Tips

- As with [merit.beamformer.DAS](DAS.md), the squares of complex values are complex squares; take `abs` of the image.
- Because both E and the denominator are complex for frequency-domain signals, F is complex and is not confined to the range from 0 to C.

## See Also

[merit.beamformer.DAS](DAS.md) | [merit.beamformer.DMAS](DMAS.md) | [merit.beamform](../beamform.md)
