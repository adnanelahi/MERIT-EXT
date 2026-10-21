# MERIT-EXT documentation

MERIT-EXT adds tools to the MERIT microwave imaging toolbox. It contains two packages:

- `signalvis` displays and compares channel signals.
- `artefact` forms antenna neighbourhoods and reference channels for removing the early-time artefact.

## Getting started

- [Getting Started with MERIT-EXT](getting-started.md): requirements, folder layout, cloning MERIT and MERIT-EXT, setting the path, checking the installation, running the examples, data conventions and a first session.

## Tutorials

- [From Measured Scans to an Image with Average Subtraction](tutorials/average-subtraction-pipeline.md): a complete script, built step by step, that converts a Galway scan to the time domain, removes the artefact by rotation subtraction and by average subtraction, views the signals, beamforms, displays the images and compares them with image metrics.

## Extending

- [Extending MERIT and MERIT-EXT](extending.md): writing your own beamformers, delay functions, windows and artefact-removal methods, and proposing them for inclusion. Methods to implement are listed in [TODO](../TODO.md).

## Functions

### signalvis: signal display

| Function | Purpose |
|---|---|
| [signalViewer](signalvis/signalViewer.md) | Choose interactively which channel signals to display and compare. |
| [inspectPointDelays](signalvis/inspectPointDelays.md) | Compare original signals with the signals delayed for one imaging point. |

### artefact: early-time artefact removal

| Function | Purpose |
|---|---|
| [antennaNeighbours](artefact/antennaNeighbours.md) | Neighbourhood of each antenna from the antenna positions. |
| [referenceChannels](artefact/referenceChannels.md) | Reference channels of each channel from the neighbourhoods. |
| [neighbourhoodEditor](artefact/neighbourhoodEditor.md) | Show and edit neighbourhoods and reference channels. |
| [subtractAverage](artefact/subtractAverage.md) | Remove the artefact by subtracting the average of reference channels. |

## MERIT

The documentation of the MERIT toolbox itself is kept in two folders, one for each version, so that it can later move into MERIT:

- [MERIT 1.0.1](merit/README.md), the current version, which needs MATLAB R2021a or later.
- [MERIT 2019 snapshot](merit-2019/README.md), commit `03ea497`, which runs on older MATLAB releases and is the version with which MERIT-EXT is tested.

## Examples

- [Compare Original, Rotated and Rotation-Subtracted Scans](examples/compare-scans.md)
- [Antenna Neighbourhoods and Reference Channels](examples/neighbourhoods.md)

## In MATLAB

`help signalvis` and `help artefact` list the functions of each package. `help signalvis.signalViewer` (or any other function) prints its summary help. The scripts in the `examples` folder run each function on synthetic data and on the Galway phantom data supplied with MERIT.

The figures and window images in `images/` are created by `images/makeFigures.m`; run it with MERIT and MERIT-EXT on the path to recreate them after a change.
