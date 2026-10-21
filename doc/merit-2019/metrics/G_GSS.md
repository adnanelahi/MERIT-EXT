# merit.metrics.G_GSS

Gradient-based focal quality metric

Package: `merit.metrics`

This function cannot be run in the 2019 snapshot: it calls `merit.beamform.un_imaging_domain`, which does not exist in any version of MERIT, and stops with the error `Undefined variable "merit" or class "merit.beamform.un_imaging_domain"`. This page describes the calculation that the code is written to perform.

## Syntax

```text
f = merit.metrics.G_GSS(imgs, points, axes_)
```

## Description

`f = merit.metrics.G_GSS(imgs, points, axes_)` is intended to return, for each image in the columns of `imgs`, the mean squared magnitude of the image gradient estimated with derivative-of-Gaussian filters. Sharply focused images have larger gradients and therefore larger values. Metrics of this kind were used as fitness functions in D. O'Loughlin et al., "Parameter search algorithms for microwave radar-based breast imaging: focal quality metrics as fitness functions", Sensors 17, 2823, 2017.

## Input Arguments

### `imgs` — images

P x K array, one image per column

### `points` — point coordinates

P x 3 array

### `axes_` — grid axes

1 x 3 cell array

## Output Arguments

### `f` — focal quality of each image

1 x K vector

## Algorithms

The code places the point indices on the grid, cuts the grid into all blocks of 15 x 15 x 15 samples that lie entirely inside the domain, and filters each block with the x, y and z derivatives of a Gaussian of standard deviation 2.8 samples, each normalised to unit sum. The value for an image is the mean over the blocks of the sum of the three squared filter responses.

## Tips

- The missing function would have to perform the operation of [merit.domain.img2grid](../domain/img2grid.md); replacing the call with `merit.domain.img2grid(inds, points, axes_{:})` is the likely correction, but it has not been tested.

## See Also

[merit.metrics.FWHM](FWHM.md) | [merit.domain.img2grid](../domain/img2grid.md)
