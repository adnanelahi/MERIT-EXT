# merit.beamformers.CDAS

Delay-and-sum beamformer weighted by a coherence factor

Package: `merit.beamformers`

## Syntax

```text
image_ = merit.beamformers.CDAS()
```

## Description

`image_ = merit.beamformers.CDAS()` returns a beamformer for [merit.beamform](../beamform.md) that multiplies the delay-and-sum value of each point by a coherence factor. The factor is large where the delayed channels agree and small where they do not, which suppresses clutter.

## Examples

### Compare delay-and-sum with its coherence-weighted form

```matlab
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

points = merit.domain.hemisphere('radius', 7e-2, 'resolution', 5e-3);
delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
img_das = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));
img_cdas = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.CDAS));
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

- As with [merit.beamformers.DAS](DAS.md), the squares of complex values are complex squares; take `abs` of the image.
- Because both E and the denominator are complex for frequency-domain signals, F is complex and is not confined to the range from 0 to C. On the rotation-subtracted scan B0_P3 at a grid spacing of 2.5 mm, the maximum of the coherence-weighted image lies at (5, 2.5, 10) mm, away from the tumour at (15, 0, 35) mm, whereas delay-and-sum places it at (15, 2.5, 27.5) mm.

## See Also

[merit.beamformers.DAS](DAS.md) | [merit.beamformers.DMAS](DMAS.md) | [merit.beamform](../beamform.md)
