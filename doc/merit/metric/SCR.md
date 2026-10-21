# merit.metric.SCR

Signal-to-clutter ratio of an image

Package: `merit.metric`

## Syntax

```text
[scr, next] = merit.metric.SCR(img, points, x, y, z)
[scr, next] = merit.metric.SCR(img, points, location, x, y, z)
[scr, next] = merit.metric.SCR(img, points)
```

## Description

`[scr, next] = merit.metric.SCR(img, points, x, y, z)` returns the ratio, in decibels, of the maximum of the image within the response at its maximum to the largest value outside that response. The response is the ellipsoid whose semi-axes equal the full widths at half maximum from [merit.metric.FWHM](FWHM.md). `next` is the location of the largest value outside the response, the strongest clutter.

`[scr, next] = merit.metric.SCR(img, points, location, x, y, z)` centres the response at `location` instead of at the maximum.

`[scr, next] = merit.metric.SCR(img, points)` uses widths counted in grid steps; see Tips.

## Examples

### Signal-to-clutter ratio of a delay-and-sum image

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));

[scr, next] = merit.metric.SCR(img, points, axes_{:})
```


## Input Arguments

### `img` — image values

P x 1 vector of non-negative real values

### `points` — point coordinates

P x 3 array, in metres

### `x`, `y`, `z` — grid axes

vectors

### `location` — centre of the response

1 x 3 vector, one of the rows of `points`

## Output Arguments

### `scr` — signal-to-clutter ratio

scalar, in decibels

`10*log10(max inside / max outside)`. If every point lies inside the response, `scr` is 0.

### `next` — location of the strongest clutter

1 x 3 vector

## Tips

- Pass the grid axes. Without them, the widths are counted in grid steps while the points are in metres, so the ellipsoid contains every point and `scr` is 0.
- The ratio uses 10 log10, which treats the image values as powers, as the beamformers of MERIT produce.
- The ellipsoid uses the full widths as semi-axes, so it is twice as large in each direction as the region within half the maximum.

## See Also

[merit.metric.FWHM](FWHM.md) | [merit.metric.SMR](SMR.md)
