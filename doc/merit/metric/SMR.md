# merit.metric.SMR

Signal-to-mean ratio of an image

Package: `merit.metric`

## Syntax

```text
smr = merit.metric.SMR(img, points, x, y, z)
smr = merit.metric.SMR(img, points, location, x, y, z)
smr = merit.metric.SMR(img, points)
```

## Description

`smr = merit.metric.SMR(img, points, x, y, z)` returns the ratio, in decibels, of the maximum of the image within the response at its maximum to the mean of the whole image. The response is defined as in [merit.metric.SCR](SCR.md).

`smr = merit.metric.SMR(img, points, location, x, y, z)` centres the response at `location`.

## Examples

### Signal-to-mean ratio of a delay-and-sum image

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));

smr = merit.metric.SMR(img, points, axes_{:})
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

### `smr` — signal-to-mean ratio

scalar, in decibels

`10*log10(max inside / mean(img))`

## Tips

- When the response is centred at the maximum of the image, the maximum inside it is the maximum of the image, so the result does not depend on the widths and the axes may be omitted.
- The mean includes every point of the domain, so a larger domain with low values raises the ratio.

## See Also

[merit.metric.SCR](SCR.md) | [merit.metric.FWHM](FWHM.md)
