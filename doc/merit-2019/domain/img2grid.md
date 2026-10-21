# merit.domain.img2grid

Place image values given at a list of points onto a regular grid

Package: `merit.domain`

## Syntax

```text
grid_ = merit.domain.img2grid(img, points, axis1, ..., axisD)
grid_ = merit.domain.img2grid(img, subscripts)
```

## Description

`grid_ = merit.domain.img2grid(img, points, axis1, ..., axisD)` returns an array of size `numel(axis1)` x ... x `numel(axisD)` that holds `img(k)` at the grid position of `points(k, :)` and `NaN` elsewhere.

`grid_ = merit.domain.img2grid(img, subscripts)` treats the rows of `subscripts` as integer grid subscripts. The grid is then as large as the largest subscripts.

## Examples

### Convert an image to a three-dimensional array

```matlab
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 5e-3);
delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));

grid_ = merit.domain.img2grid(img, points, axes_{:});
size(grid_)
```

`grid_(i, j, k)` is the image value at `(axes_{1}(i), axes_{2}(j), axes_{3}(k))`.

### Grid from subscripts

```matlab
merit.domain.img2grid([5 6 7]', [1 1; 2 1; 2 2])
```

The result is `[5 NaN; 6 7]`.

## Input Arguments

### `img` — image values

P x 1 vector

One value for each row of `points`.

### `points` — point coordinates

P x D array

Coordinates in the units of the axes. Each coordinate must match a value of the corresponding axis to within 1e-6.

### `axis1, ..., axisD` — grid axes

vectors

One axis for each column of `points`. If the number of axes differs from the number of columns, the points are treated as subscripts.

## Output Arguments

### `grid_` — image on the grid

D-dimensional array

The first dimension follows `axis1`, the second `axis2`, and so on. Grid positions without a point are `NaN`.

## Tips

- If two points map to the same grid position, their values are added.
- [merit.visualize.get_slice](../visualize/get_slice.md) uses this function to extract a single plane.

## See Also

[merit.beamform.imaging_domain](../beamform/imaging_domain.md) | [merit.visualize.get_slice](../visualize/get_slice.md) | [merit.domain.hemisphere](hemisphere.md)
