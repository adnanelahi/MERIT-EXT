# MERIT documentation for the 2019 snapshot

These pages document the MERIT snapshot of 4 July 2019 (commit `03ea497`), the last version of MERIT that runs on MATLAB releases before R2019b. The documentation for MERIT 1.0.1 is in [../merit](../merit/README.md). The two versions differ in the names of several packages and functions and in the syntax of some functions; each page here describes the 2019 snapshot only.

Every code block in these pages was run on MATLAB R2018a with the Signal Processing Toolbox. The examples assume that the MERIT folder is on the MATLAB path and is the current folder, so that the files in its `data` folder can be read with relative paths.

## Getting started

- [Getting Started with MERIT (2019 snapshot)](getting-started.md): installation, the example data, and an imaging pipeline from loading the scans to displaying an image slice.

## Functions

### Beamforming

| Function | Purpose |
|---|---|
| [merit.beamform](beamform.md) | Form an image by delaying the signals for each imaging point and combining them with a beamformer. |
| [merit.beamform.get_delays](beamform/get_delays.md) | Create a function that returns the propagation delay of every channel to given points. |
| [merit.beamform.imaging_domain](beamform/imaging_domain.md) | Convert a logical mask and its axes to a list of points. |
| [merit.beamform.windows.rectangular](beamform/windows/rectangular.md) | Create a window that keeps the first samples of the delayed signals. |

### Beamformers

| Function | Purpose |
|---|---|
| [merit.beamformers.DAS](beamformers/DAS.md) | Delay-and-sum beamformer. |
| [merit.beamformers.CDAS](beamformers/CDAS.md) | Delay-and-sum beamformer weighted by a coherence factor. |
| [merit.beamformers.DMAS](beamformers/DMAS.md) | Delay-multiply-and-sum beamformer. |

### Imaging domain

| Function | Purpose |
|---|---|
| [merit.domain.hemisphere](domain/hemisphere.md) | Points on a regular grid inside a hemisphere. |
| [merit.domain.img2grid](domain/img2grid.md) | Place image values given at a list of points onto a regular grid. |

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

### Image metrics

| Function | Purpose |
|---|---|
| [merit.metrics.FWHM](metrics/FWHM.md) | Full width at half maximum of an image along the three axes. |
| [merit.metrics.SCR](metrics/SCR.md) | Signal-to-clutter ratio of an image. |
| [merit.metrics.SMR](metrics/SMR.md) | Signal-to-mean ratio of an image. |
| [merit.metrics.G_GSS](metrics/G_GSS.md) | Gradient-based focal quality metric; this function cannot be run in the 2019 snapshot. |

### Visualisation

| Function | Purpose |
|---|---|
| [merit.visualize.get_slice](visualize/get_slice.md) | Extract a slice of constant z from an image as a two-dimensional grid. |

### Utilities

| Function | Purpose |
|---|---|
| [merit.utility.expand](utility/expand.md) | Replicate arrays along their singleton dimensions to a common size. |
| [merit.utility.expand2](utility/expand2.md) | Replicate arrays to a common size in every dimension except the first. |
| [merit.utility.linearlysampled](utility/linearlysampled.md) | Test whether an axis has a constant step. |
| [merit.utility.reshape2d](utility/reshape2d.md) | Apply a function written for matrices to arrays with more dimensions. |
| [merit.utility.under](utility/under.md) | Apply a function between a transformation of its inputs and a transformation of its output. |

### Tests

| Function | Purpose |
|---|---|
| [merit.run_tests](run_tests.md) | Run the unit tests in the package `merit.tests`. |

## Example scripts

The snapshot contains three scripts. `getting_started.m` in the MERIT folder follows the pipeline described in [Getting Started](getting-started.md). `merit.examples.image_B0` and `merit.examples.image_B10E` image two tumour positions in the phantoms B0 and B10E, the second restricted to the band from 2 GHz to 4 GHz; both read the `data` folder relative to the current folder.
