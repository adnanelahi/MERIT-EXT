# MERIT documentation

These pages document MERIT 1.0.1, the version on the `master` branch of the MERIT repository since 18 October 2026 (commit `5ef9567`). Version 1.0.1 needs MATLAB R2021a or later. For older MATLAB releases, use the MERIT snapshot of 4 July 2019, documented in [../merit-2019](../merit-2019/README.md); the two versions differ in the names of several packages and functions and in the syntax of some functions.

The pages were written from the code of version 1.0.1. Their examples have not been run, because only MATLAB R2018a was available when they were written; the corresponding examples of the 2019 snapshot were run. The examples assume that the MERIT folder is on the MATLAB path and is the current folder, so that the files in its `example_data` folder can be read with relative paths.

## Getting started

- [Getting Started with MERIT](getting-started.md): installation, the example data, and an imaging pipeline from loading the scans to displaying the image in three dimensions.

## Functions

### Beamforming

| Function | Purpose |
|---|---|
| [merit.beamform](beamform.md) | Form an image by delaying the signals for each imaging point and combining them with a beamformer. |
| [merit.get_delay](get_delay.md) | Create a function that returns the propagation delay of every channel to given points. |

### Beamformers

| Function | Purpose |
|---|---|
| [merit.beamformer.DAS](beamformer/DAS.md) | Delay-and-sum beamformer. |
| [merit.beamformer.CDAS](beamformer/CDAS.md) | Delay-and-sum beamformer weighted by a coherence factor. |
| [merit.beamformer.DMAS](beamformer/DMAS.md) | Delay-multiply-and-sum beamformer. |

### Imaging domain

| Function | Purpose |
|---|---|
| [merit.domain.hemisphere](domain/hemisphere.md) | Points on a regular grid inside a hemisphere or a circle. |
| [merit.domain.circumference](domain/circumference.md) | Points spaced evenly around a circle. |
| [merit.domain.get_points](domain/get_points.md) | Convert a logical mask and its axes to a list of points. |
| [merit.domain.img2grid](domain/img2grid.md) | Place image values given at a list of points onto a regular grid. |
| [merit.domain.get_slice](domain/get_slice.md) | Extract a slice of constant z from an image as a two-dimensional grid. |
| [merit.domain.windows.rectangular](domain/windows/rectangular.md) | Create a window that keeps the first samples of the delayed signals. |

### Signal processing

| Function | Purpose |
|---|---|
| [merit.process.delay](process/delay.md) | Delay signals in the time or the frequency domain. |
| [merit.process.fd2td](process/fd2td.md) | Convert frequency-domain signals to the time domain with the inverse chirp-z transform. |
| [merit.process.td2fd](process/td2fd.md) | Convert time-domain signals to the frequency domain with the chirp-z transform. |
| [merit.process.shape](process/shape.md) | Multiply frequency-domain signals by a pulse spectrum and convert them to the time domain. |
| [merit.process.resample](process/resample.md) | Resample time-domain signals to a new sampling frequency. |
| [merit.process.remap](process/remap.md) | Rename antennas and reorder the channels accordingly. |
| [merit.process.txrx2ind](process/txrx2ind.md) | Find the indices of channels from their transmitting and receiving antennas. |
| [merit.process.expand](process/expand.md) | Replicate arrays along their singleton dimensions to a common size. |
| [merit.process.expand2](process/expand2.md) | Replicate arrays to a common size in every dimension except the first. |
| [merit.process.linearlysampled](process/linearlysampled.md) | Test whether an axis has a constant step. |
| [merit.process.reshape2d](process/reshape2d.md) | Apply a function written for matrices to arrays with more dimensions. |
| [merit.process.under](process/under.md) | Apply a function between a transformation of its inputs and a transformation of its output. |

### Image metrics

| Function | Purpose |
|---|---|
| [merit.metric.FWHM](metric/FWHM.md) | Full width at half maximum of an image along the three axes. |
| [merit.metric.SCR](metric/SCR.md) | Signal-to-clutter ratio of an image. |
| [merit.metric.SMR](metric/SMR.md) | Signal-to-mean ratio of an image. |
| [merit.metric.G_GSS](metric/G_GSS.md) | Gradient-based focal quality metric; this function cannot be run. |

### Display

| Function | Purpose |
|---|---|
| [merit.display.as_3D_scan](display/as_3D_scan.md) | Display a three-dimensional image as semi-transparent slices. |

### Testing and performance

| Function | Purpose |
|---|---|
| [merit.test.run_all](test/run_all.md) | Run the unit tests in the package `merit.test.from_list`. |
| [merit.test.time_this](test/time_this.md) | Measure the time taken by one call of a function. |
| [merit.test.profile_this](test/profile_this.md) | Profile one call of a function. |

## Scripts

| Script | Content |
|---|---|
| `getting_started.m` | The pipeline described in [Getting Started](getting-started.md). |
| `load_example_scan.m` | Function that reads a scan and its rotated scan from `example_data` by phantom and tumour position. |
| `merit.example_scripts.plot_mag_and_phase` | Magnitude and phase of the first channel before and after rotation subtraction. |
| `merit.example_scripts.measure_performance` | Comparison of the time taken by `merit.process.delay` in double and single precision. |
| `merit.example_scripts.create_ummid_render` | Two-dimensional monostatic image of a UM-BMID scan; needs the UM-BMID dataset in `../um_bmid/datasets/`. |

## Names in earlier versions

| Version 1.0.1 | Version 1.0.0 | 2019 snapshot |
|---|---|---|
| `merit.get_delay` | `merit.beamform.get_delays` | `merit.beamform.get_delays` |
| `merit.beamformer.*` | `merit.beamformers.*` | `merit.beamformers.*` |
| `merit.metric.*` | `merit.metrics.*` | `merit.metrics.*` |
| `merit.domain.get_points` | `merit.beamform.imaging_domain` | `merit.beamform.imaging_domain` |
| `merit.domain.get_slice` | `merit.visualize.get_slice` | `merit.visualize.get_slice` |
| `merit.domain.windows.rectangular` | `merit.beamform.windows.rectangular` | `merit.beamform.windows.rectangular` |
| `merit.domain.circumference` | `merit.domain.create_circumference` | none |
| `merit.display.as_3D_scan` | `merit.visualize.display_3D_scan` | none |
| `merit.process.expand`, `expand2`, `linearlysampled`, `reshape2d`, `under` | `merit.utility.*` (without `expand2`) | `merit.utility.*` |
| `merit.test.run_all` | `merit.test.run_all` | `merit.run_tests` |
| `merit.test.time_this`, `profile_this` | the same | none |

The CHANGELOG of version 1.0.1 states that `+windows` and `imaging_domain` were moved to `+process`; in the code they are in `+domain`, as listed here.
