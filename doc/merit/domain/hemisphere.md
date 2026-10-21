# merit.domain.hemisphere

Points on a regular grid inside a hemisphere or a circle

Package: `merit.domain`

## Syntax

```text
[points, axes_] = merit.domain.hemisphere(radius, resolution=res)
[points, axes_] = merit.domain.hemisphere(radius, pixel_dim=n)
[points, axes_] = merit.domain.hemisphere(___, no_z=true)
```

## Description

`[points, axes_] = merit.domain.hemisphere(radius, resolution=res)` returns the points of a regular grid with spacing `res` that lie inside a hemisphere of radius `radius`, centred on the origin, with z ≥ 0.

`[points, axes_] = merit.domain.hemisphere(radius, pixel_dim=n)` chooses the spacing so that the x and y axes have `n` values across the diameter.

`[points, axes_] = merit.domain.hemisphere(___, no_z=true)` returns the points of a two-dimensional grid inside a circle of radius `radius` instead.

## Examples

### Imaging domain for the Galway phantoms

```matlab
[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
cellfun(@numel, axes_)
```

The x and y axes run from -70 mm to 70 mm and the z axis from 0 to 70 mm, giving 57, 57 and 29 values.

### Different spacing along z

```matlab
[points, axes_] = merit.domain.hemisphere(5e-2, resolution=[5e-3 5e-3 1e-2]);
```

### A two-dimensional domain of 50 by 50 pixels

```matlab
[points, axes_] = merit.domain.hemisphere(8e-2, pixel_dim=50, no_z=true);
size(points, 2)
```

`points` has two columns, x and y, and `axes_` holds two axes, each with 50 values from -80 mm to 80 mm.

## Input Arguments

### `radius` — radius in metres

real scalar

## Name-Value Arguments

Exactly one of `resolution` and `pixel_dim` must be given.

| Name | Value | Default | Description |
|---|---|---|---|
| `resolution` | real scalar or vector | `[]` | Grid spacing in metres, either for all axes or for x, y and z separately. |
| `pixel_dim` | positive scalar or vector | `[]` | Number of grid values across the diameter. The spacing is `2*radius ./ (pixel_dim - 1)`; a scalar applies to all axes. |
| `no_z` | logical | `false` | Return a circle in the plane z = 0 with two coordinates per point. |

## Output Arguments

### `points` — grid points inside the hemisphere or circle

P x 3 array | P x 2 array with `no_z=true`

The coordinates in metres of every grid point that satisfies x² + y² + z² ≤ radius² (or x² + y² ≤ radius²), with x varying fastest, then y, then z.

### `axes_` — grid axes

1 x 3 cell array | 1 x 2 cell array with `no_z=true`

The grid axes, needed by [merit.domain.img2grid](img2grid.md), [merit.domain.get_slice](get_slice.md) and the image metrics.

## Algorithms

The x and y axes run from `-radius` to `radius` and the z axis from 0 to `radius`, each in steps of the spacing. [merit.domain.get_points](get_points.md) then selects the grid points within the radius.

## Tips

- The radius is the first input. The form used before version 1.0, `hemisphere('radius', r, 'resolution', res)`, stops with an error because `'radius'` is taken as the radius; the example in the README of MERIT before version 1.0.1 used this form.
- With `pixel_dim`, the z axis uses the same spacing as x and y, so it has about half as many values.
- The axes end at the radius. Before version 1.0 they extended 5 mm beyond it, and the options `x`, `y` and `z` for giving the axes directly were removed.
- The number of points grows with the inverse cube of the spacing, and the time taken by [merit.beamform](../beamform.md) grows with it.

## See Also

[merit.domain.get_points](get_points.md) | [merit.domain.img2grid](img2grid.md) | [merit.domain.circumference](circumference.md) | [merit.beamform](../beamform.md)
