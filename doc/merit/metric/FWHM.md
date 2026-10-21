# merit.metric.FWHM

Full width at half maximum of an image along the three axes

Package: `merit.metric`

## Syntax

```text
[w_x, w_y, w_z] = merit.metric.FWHM(img, points)
[w_x, w_y, w_z] = merit.metric.FWHM(img, points, x, y, z)
[w_x, w_y, w_z] = merit.metric.FWHM(img, points, location)
[w_x, w_y, w_z] = merit.metric.FWHM(img, points, location, x, y, z)
w = merit.metric.FWHM(___)
```

## Description

`[w_x, w_y, w_z] = merit.metric.FWHM(img, points)` measures the width of the response at the maximum of the image along lines parallel to the x, y and z axes, counted in grid steps.

`[w_x, w_y, w_z] = merit.metric.FWHM(img, points, x, y, z)` converts the widths to metres using the spacing of the grid axes.

`[w_x, w_y, w_z] = merit.metric.FWHM(img, points, location)` measures the widths at `location` instead of at the maximum.

`w = merit.metric.FWHM(___)` returns the mean of the three widths.

## Examples

### Widths of the tumour response

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));

[w_x, w_y, w_z] = merit.metric.FWHM(img, points, axes_{:})
w = merit.metric.FWHM(img, points, axes_{:})
```

The widths are in metres because the axes are given.

## Input Arguments

### `img` — image values

P x 1 vector of non-negative real values

### `points` — point coordinates

P x 3 array

### `x`, `y`, `z` — grid axes

vectors

The axes returned by [merit.domain.hemisphere](../domain/hemisphere.md). Only the spacing of each axis, `diff(x(1:2))`, is used.

### `location` — point at which to measure

1 x 3 vector

Must be one of the rows of `points`.

## Output Arguments

### `w_x`, `w_y`, `w_z` — widths along x, y and z

scalars, in grid steps or in metres

### `w` — mean width

scalar

## Algorithms

Along each line through the location, the function finds the nearest sample on either side of the maximum of the line that is below half that maximum. The width is the number of samples strictly between them. If no sample on one side falls below half the maximum, the end of the line is used.

## Tips

- The maximum of each line is used, not the value at the location, so a location away from a peak can give misleading widths.
- The width is counted in whole samples, so it is quantised by the grid spacing.

## See Also

[merit.metric.SCR](SCR.md) | [merit.metric.SMR](SMR.md)
