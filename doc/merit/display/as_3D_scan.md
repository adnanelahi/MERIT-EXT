# merit.display.as_3D_scan

Display a three-dimensional image as semi-transparent slices

Package: `merit.display`

## Syntax

```text
merit.display.as_3D_scan(grid_)
merit.display.as_3D_scan(grid_, Name=Value)
```

## Description

`merit.display.as_3D_scan(grid_)` opens a new figure and draws every plane of the three-dimensional array `grid_` in each of the three directions, coloured by value. The opacity increases with the value, so the strongest responses are opaque and weak values are almost transparent.

`merit.display.as_3D_scan(grid_, Name=Value)` sets the figure, the colour map or the opacities.

## Examples

### Display a delay-and-sum image in three dimensions

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));

grid_ = merit.domain.img2grid(img, points, axes_{:});
merit.display.as_3D_scan(grid_);
```

This is the last step of `getting_started.m` and produces the figure shown in the README of MERIT.

### Make the weaker values more visible

```matlab
merit.display.as_3D_scan(grid_, middle_opacity_factor=0.8, colormap="parula");
```

## Input Arguments

### `grid_` — image on a grid

three-dimensional numeric array

The output of [merit.domain.img2grid](../domain/img2grid.md). `NaN` values, such as the points outside a hemisphere, are not drawn.

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `figure_number` | non-negative integer | `0` | Figure in which to draw; 0 opens a new figure. |
| `upper_opacity` | scalar in (0, 1] | `1` | Opacity reached at the 90th percentile of the values. |
| `middle_opacity_factor` | scalar in (0, 1] | `0.4` | Opacity at the upper quartile, as a fraction of `upper_opacity`. |
| `lower_opacity_factor` | scalar in (0, 1] | `0.1` | Opacity at the lower quartile, as a fraction of the opacity at the upper quartile. |
| `colormap` | colour map name or M x 3 array | `"jet"` | Colour map of the figure. |

## Algorithms

The function draws the planes with `slice` and sets `alpha('color')`, so that the opacity of each face follows its value through the figure's alpha map. The alpha map consists of four linear segments: from 0.01 to the lower opacity, to the middle opacity, to `upper_opacity` and to 1. The segments are meant to start at the minimum, the lower quartile, the upper quartile and the 90th percentile of the non-zero, non-`NaN` values. The number of entries of each segment is the full value range divided by the width of the corresponding value range.

## Tips

- Because MATLAB spreads the alpha map evenly over the value range, a segment with more entries covers a larger part of the range. The number of entries is inversely proportional to the width of the value range, so the opacity steps do not fall at the quartiles unless the four ranges are equally wide.
- The grid is drawn with `meshgrid(1:lx, 1:ly, 1:lz)`, so the axes show grid indices rather than metres. `meshgrid` places the first dimension of the array along the y axis of the figure, so the figure's x and y axes are exchanged relative to the grid. If the first two dimensions of `grid_` differ in size, `slice` stops with an error.
- The figure title is always "3D Scan Density Visualization".
- The function calls `quantile`, from the Statistics and Machine Learning Toolbox, and validates its options with `mustBeInRange`, available from MATLAB R2020b.
- The function was called `merit.visualize.display_3D_scan` in version 1.0.0.

## See Also

[merit.domain.img2grid](../domain/img2grid.md) | [merit.domain.get_slice](../domain/get_slice.md)
