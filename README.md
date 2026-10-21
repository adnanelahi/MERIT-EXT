# MERIT-EXT

MERIT-EXT (MERIT Extensions) contains MATLAB extensions to the MERIT microwave imaging toolbox, intended for eventual integration into MERIT. The package `signalvis` displays and compares signals; the package `artefact` forms antenna neighbourhoods and reference channels and performs average subtraction. The project is kept in a folder of its own, next to MERIT, so that it can be developed and versioned without modifying third-party files.

## Layout

```text
MERIT-EXT/
  README.md
  +signalvis/       % signal display: signalViewer, inspectPointDelays; unit tests in +signalvis/+test
  +artefact/        % artefact removal: neighbourhoods, reference channels, average subtraction; unit tests in +artefact/+test
  doc/             % user documentation (Markdown): getting started, reference pages, examples
  examples/        % synthetic and MERIT data usage
```

## Documentation

The user documentation is in [doc/README.md](doc/README.md): [Getting Started](doc/getting-started.md), one reference page per function and worked examples. In MATLAB, `help signalvis` and `help artefact` list each package's functions. [Extending MERIT and MERIT-EXT](doc/extending.md) explains where to write new methods and how to propose them for inclusion, and [TODO.md](TODO.md) lists methods to implement.

## Setup in MATLAB

Place MERIT, MERIT-EXT and your own code in separate folders under one parent folder, and keep your own scripts and functions out of the MERIT and MERIT-EXT folders:

```text
<parent>/
  MERIT/        % MERIT at the tested commit
  MERIT-EXT/    % this project
  my-project/   % your own code, or in a subfolder such as projects/my-project
```

Add only the MERIT and MERIT-EXT root folders to the path:

```matlab
parent = 'C:\work\merit';
addpath(fullfile(parent, 'MERIT'));
addpath(fullfile(parent, 'MERIT-EXT'));
which merit.process.delay   % must resolve to your MERIT folder
```

If a clone of a newer MERIT release is on the path, remove it first; both define the package `merit`. [Getting Started](doc/getting-started.md) gives a `setupPaths` script with which a project folder sets the path.

## Current functions

- `signalvis.signalViewer`: an interactive viewer for one or several samples x channels arrays (complex signals, real waveforms, magnitudes in linear or dB, or phases). Signals are chosen by ticking Tx and Rx antennas, single channels, antenna groups and datasets, and shown overlaid or in paged panels. See [signalViewer](doc/signalvis/signalViewer.md).
- `signalvis.inspectPointDelays`: selects a point on a point map or beamformer image by clicking and compares the original signals with the signals delayed for that point.
- `artefact.antennaNeighbours`, `artefact.referenceChannels`, `artefact.neighbourhoodEditor`: give each antenna a neighbourhood (within a distance, which is the default, the k nearest antennas, or by hand) and derive each channel's reference channels for later average subtraction.

Each function's help text (`help signalvis.signalViewer`) describes its options. The scripts in `examples/` run each function on synthetic data and on the local Galway phantom data; start with `viewMeritSignals.m`. The tutorial [From Measured Scans to an Image with Average Subtraction](doc/tutorials/average-subtraction-pipeline.md) builds a complete processing script step by step.

## Tests

The unit tests are `matlab.unittest` test classes, as in MERIT, in the packages `signalvis.test` (`test_signal_viewer`, `test_point_inspector`) and `artefact.test` (`test_neighbourhoods`). With MERIT-EXT and MERIT on the path:

```matlab
results = runtests({'signalvis.test', 'artefact.test'});
table(results)
```

From PowerShell in this folder, headless (exit code 0 only if all tests pass; give the full path to `matlab.exe` if it is not on the system path):

```powershell
matlab -nosplash -nodesktop -minimize -wait -logfile "$env:TEMP\merit-ext-tests.log" -r "addpath(pwd); addpath(fullfile(fileparts(pwd),'MERIT')); r=runtests({'signalvis.test','artefact.test'}); disp(table(r)); exit(double(any([r.Failed]|[r.Incomplete])))"
```

The tests read the Galway phantom data supplied with MERIT, from its `data` folder (2019 snapshot) or `example_data` folder (version 1.0 and later). They use invisible figures. Mouse interaction and visual layout cannot be tested by script and need a manual check.
