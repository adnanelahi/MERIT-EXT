# merit.metrics.FWHM

Full width at half maximum of an image along the three axes

Package: `merit.metrics`

## Syntax

```text
[w_x, w_y, w_z] = merit.metrics.FWHM(img, points)
[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, x, y, z)
[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, location)
[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, location, x, y, z)
w = merit.metrics.FWHM(___)
```

## Description

`[w_x, w_y, w_z] = merit.metrics.FWHM(img, points)` measures the width of the response at the maximum of the image along lines parallel to the x, y and z axes, counted in grid steps.

`[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, x, y, z)` converts the widths to metres using the spacing of the grid axes.

`[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, location)` measures the widths at `location` instead of at the maximum.

`w = merit.metrics.FWHM(___)` returns the mean of the three widths.

## Examples

### Widths of the tumour response

```matlab
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));

[w_x, w_y, w_z] = merit.metrics.FWHM(img, points, axes_{:})
w = merit.metrics.FWHM(img, points, axes_{:})
```

The widths are 17.5 mm, 10 mm and 27.5 mm, and their mean is 18.3 mm.

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

[merit.metrics.SCR](SCR.md) | [merit.metrics.SMR](SMR.md)
