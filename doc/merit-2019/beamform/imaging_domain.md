# merit.beamform.imaging_domain

Convert a logical mask and its axes to a list of points

Package: `merit.beamform`

## Syntax

```text
points = merit.beamform.imaging_domain(domain)
points = merit.beamform.imaging_domain(domain, axis1, ..., axisD)
```

## Description

`points = merit.beamform.imaging_domain(domain)` returns the subscripts of the true elements of the logical array `domain`, one element per row.

`points = merit.beamform.imaging_domain(domain, axis1, ..., axisD)` returns the coordinates of the true elements instead: the subscript in dimension d is replaced by the corresponding value of `axisd`.

## Examples

### Subscripts and coordinates of a small mask

```matlab
mask = logical([1 0; 1 1]);
merit.beamform.imaging_domain(mask)
merit.beamform.imaging_domain(mask, [10 20], [1 2])
```

The first call returns `[1 1; 2 1; 2 2]` and the second `[10 1; 20 1; 20 2]`.

### A cylindrical imaging domain

```matlab
x = -0.05:2.5e-3:0.05;
y = x;
z = 0:2.5e-3:0.04;
[X, Y, ~] = ndgrid(x, y, z);
points = merit.beamform.imaging_domain(X.^2 + Y.^2 <= 0.05^2, x, y, z);
size(points)
```

## Input Arguments

### `domain` — mask of the points to include

logical array

True for each grid element that belongs to the imaging domain.

### `axis1, ..., axisD` — grid axes

vectors

The coordinate of each grid index in each dimension, so that `numel(axisd)` equals `size(domain, d)`.

## Output Arguments

### `points` — subscripts or coordinates of the included elements

M x D array

One row for each of the M true elements of `domain`, in the order of linear indexing: the first dimension varies fastest.

## Tips

- [merit.domain.img2grid](../domain/img2grid.md) performs the inverse operation: it places values given at these points back onto the grid.

## See Also

[merit.domain.hemisphere](../domain/hemisphere.md) | [merit.domain.img2grid](../domain/img2grid.md)
