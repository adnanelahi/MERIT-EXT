# merit.domain.hemisphere

Points on a regular grid inside a hemisphere

Package: `merit.domain`

## Syntax

```text
[points, axes_] = merit.domain.hemisphere()
[points, axes_] = merit.domain.hemisphere(Name, Value)
```

## Description

`[points, axes_] = merit.domain.hemisphere()` returns the points of a regular grid with a spacing of 1 mm that lie inside a hemisphere of radius 7 cm, centred on the origin, with z ≥ 0.

`[points, axes_] = merit.domain.hemisphere(Name, Value)` sets the radius, the spacing, or the grid axes themselves.

## Examples

### Imaging domain for the Galway phantoms

```matlab
[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
size(points)
cellfun(@numel, axes_)
[axes_{1}(1), axes_{1}(end)]
```

The domain has 47185 points. The axes have 61, 61 and 31 values; the x axis runs from -75 mm to 75 mm, 5 mm beyond the radius.

### Different spacing along z

```matlab
[points, axes_] = merit.domain.hemisphere('radius', 5e-2, 'resolution', [5e-3 5e-3 1e-2]);
size(points)
```

### A single plane

```matlab
[points, axes_] = merit.domain.hemisphere('radius', 5e-2, 'resolution', 5e-3, 'z', 0.03);
size(points)
```

Giving the z axis as one value returns the 197 points of the disc in which the plane z = 3 cm cuts the hemisphere.

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `radius` | real scalar | `7e-2` | Radius of the hemisphere in metres. |
| `resolution` | real scalar or 3-element vector | `1e-3` | Grid spacing in metres, either for all axes or for x, y and z separately. |
| `x`, `y`, `z` | real vector | `[]` | Grid axis in metres. An axis given here replaces the axis calculated from the radius and spacing. |

## Output Arguments

### `points` — grid points inside the hemisphere

P x 3 array

The coordinates in metres of every grid point that satisfies x² + y² + z² ≤ radius², with x varying fastest, then y, then z.

### `axes_` — grid axes

1 x 3 cell array

The x, y and z axes of the grid. These are needed by [merit.domain.img2grid](img2grid.md), [merit.visualize.get_slice](../visualize/get_slice.md) and the image metrics.

## Algorithms

Unless given, the x and y axes run from -(radius + 5 mm) to radius + 5 mm, and the z axis from 0 to radius + 5 mm, each in steps of the spacing. [merit.beamform.imaging_domain](../beamform/imaging_domain.md) then selects the grid points within the radius.

## Tips

- The number of points grows with the inverse cube of the spacing: the default spacing of 1 mm gives 725759 points, about 15 times as many as a spacing of 2.5 mm, and beamforming takes correspondingly longer.
- The margin of 5 mm on the axes leaves a border of `NaN` around the hemisphere when the image is placed on the grid.

## See Also

[merit.beamform.imaging_domain](../beamform/imaging_domain.md) | [merit.domain.img2grid](img2grid.md) | [merit.beamform](../beamform.md)
