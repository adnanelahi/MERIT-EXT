# MERIT Extensions

MATLAB extensions to the MERIT microwave imaging toolbox, intended for eventual integration into MERIT. The package `signalvis` displays and compares signals; the package `artefact` forms antenna neighbourhoods and reference channels for artefact removal, and will hold the average subtraction. The project is kept outside both downloaded MERIT snapshots so that it can be developed and versioned without modifying third-party files. The interactive signal viewer is specified in [SPECIFICATION.md](SPECIFICATION.md); [BACKGROUND.md](BACKGROUND.md) collects the test environment, MERIT conventions, data geometry and release-specific limitations, and how each function would map onto MERIT.

## Layout

```text
MERIT-Extensions/
  README.md
  BACKGROUND.md
  +signalvis/       % signal display: signalViewer, inspectPointDelays
  +artefact/        % artefact removal: antenna neighbourhoods and reference channels
  doc/             % user documentation (Markdown): getting started, reference pages, examples
  examples/        % synthetic and MERIT data usage
  verification/    % scripted numerical and graphics checks
```

## Documentation

The user documentation is in [doc/README.md](doc/README.md): [Getting Started](doc/getting-started.md), one reference page per function and worked examples. In MATLAB, `help signalvis` and `help artefact` list each package's functions.

## Setup in MATLAB

Set the current folder to `MERIT-Extensions` and add this folder and only the MERIT root folder; with the layout of [doc/installation.md](doc/installation.md):

```matlab
addpath(pwd);
addpath(fullfile(fileparts(pwd), 'MERIT'));   % the MERIT clone at the tested commit; on this machine the sibling folder is MERIT-2019
which merit.process.delay   % must resolve to your MERIT folder
```

If a clone of a newer MERIT release is on the path, remove it first; both define the package `merit`.

## Current functions

- `signalvis.signalViewer`: an interactive viewer for one or several samples x channels arrays (complex signals, real waveforms, magnitudes in linear or dB, or phases). Signals are chosen by ticking Tx and Rx antennas, single channels, antenna groups and datasets, and shown overlaid or in paged panels. See [SPECIFICATION.md](SPECIFICATION.md).
- `signalvis.inspectPointDelays`: selects a point on a point map or beamformer image by clicking and compares the original signals with the signals delayed for that point.
- `artefact.antennaNeighbours`, `artefact.referenceChannels`, `artefact.neighbourhoodEditor`: give each antenna a neighbourhood (k nearest, within a distance, or by hand) and derive each channel's reference channels for later average subtraction.

Each function's help text (`help signalvis.signalViewer`) describes its options. The scripts in `examples/` run each function on synthetic data and on the local Galway phantom data; start with `viewMeritSignals.m`.

## Verification

From MATLAB:

```matlab
addpath(fullfile(pwd, 'verification'));
verify_signal_viewer();
verify_point_inspector();
verify_neighbourhoods();
```

From PowerShell in this folder, headless (exit code 0 only if all suites pass; give the full path to `matlab.exe` if it is not on the system path):

```powershell
matlab -nosplash -nodesktop -minimize -wait -logfile "$env:TEMP\signalvis-verification.log" -r "addpath(pwd); addpath(fullfile(fileparts(pwd),'MERIT')); addpath('verification'); ok=true; try; verify_signal_viewer(); catch p; disp(getReport(p)); ok=false; end; try; verify_point_inspector(); catch p; disp(getReport(p)); ok=false; end; try; verify_neighbourhoods(); catch p; disp(getReport(p)); ok=false; end; exit(double(~ok))"
```

The suites use invisible figures and report each group as PASS or FAIL. Mouse interaction and visual layout cannot be tested by script and need a manual check.
