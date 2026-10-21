# merit.domain.get_slice

Extract a slice of constant z from an image as a two-dimensional grid

Package: `merit.domain`

## Syntax

```text
im_slice = merit.domain.get_slice(img, points, axes_)
im_slice = merit.domain.get_slice(img, points, axes_, z=z)
```

## Description

`im_slice = merit.domain.get_slice(img, points, axes_)` returns the values of the image in the plane z = 0 as a grid with one row for each value of the x axis and one column for each value of the y axis.

`im_slice = merit.domain.get_slice(img, points, axes_, z=z)` returns the plane at height `z`.

## Examples

### Display the plane through the tumour

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));

im_slice = merit.domain.get_slice(img, points, axes_, z=35e-3);
figure;
imagesc(axes_{1}*1e3, axes_{2}*1e3, im_slice.');
axis xy equal tight;
xlabel('x (mm)');
ylabel('y (mm)');
colorbar;
```

### Display the plane of the maximum

```matlab
[~, peak] = max(img);
im_slice = merit.domain.get_slice(img, points, axes_, z=points(peak, 3));
```

## Input Arguments

### `img` — image values

P x 1 vector

### `points` — point coordinates

P x 3 array, in metres

### `axes_` — grid axes

1 x 3 cell array, as returned by [merit.domain.hemisphere](hemisphere.md)

### `z` — height of the slice

scalar, in metres (default `0`)

Must equal one of the z values of the points to within 1e-6.

## Output Arguments

### `im_slice` — slice of the image

`numel(axes_{1})` x `numel(axes_{2})` array

`im_slice(i, j)` is the value at x = `axes_{1}(i)` and y = `axes_{2}(j)`. Positions outside the domain are `NaN`.

## Tips

- `imagesc(x, y, C)` draws the rows of C along the vertical axis. Transpose the slice, as in the example, to draw x horizontally. `imagesc(axes_{1:2}, im_slice)`, as written in `getting_started.m`, exchanges the x and y directions in the figure; because the two axes are equal, the axis labels do not reveal the exchange.
- `imagesc` draws the first row at the top. Use `axis xy` to put positive y upwards.
- A value of `z` that is not on the grid returns a slice that is entirely `NaN`, without a warning.

## See Also

[merit.domain.img2grid](img2grid.md) | [merit.domain.hemisphere](hemisphere.md)
