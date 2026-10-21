# Getting Started with MERIT-EXT

MERIT-EXT is a set of MATLAB packages that extend the MERIT microwave imaging toolbox. `signalvis` displays and compares the signals of antenna channels; `artefact` forms antenna neighbourhoods and reference channels for removing the early-time artefact. The code is intended for eventual integration into MERIT.

## Requirements

- MATLAB, with no additional toolboxes. `signalvis.signalViewer` and all `artefact` functions use base MATLAB only.
- MERIT on the MATLAB path, for `signalvis.inspectPointDelays`, which calls `merit.process.delay`, and for the examples, which use the Galway phantom data in MERIT's `data` folder.

**Tested with:** MATLAB R2018a and MERIT commit `03ea497` (4 July 2019). [Install MERIT-EXT and Run a First Example](installation.md) describes how to obtain both projects and check out that commit.

## Folder layout

Keep MERIT, MERIT-EXT and your own code in separate folders under one parent folder. Your own code can lie next to MERIT and MERIT-EXT or in a subfolder of the parent folder:

```text
<parent>/
  MERIT/              % MERIT, unchanged
  MERIT-EXT/          % MERIT-EXT, unchanged
  my-project/         % your own scripts and functions
  projects/           % or several projects in a subfolder
    another-project/
```

Develop in your own folder and leave the MERIT and MERIT-EXT folders unchanged. They can then be updated with `git pull` without conflicts with your files, and your project can be versioned in a repository of its own. A new function meant for one of the packages, such as an artefact-removal method for `artefact`, is also written in your own folder, as [Extending MERIT and MERIT-EXT](extending.md) describes.

## Set up the path

Save a script `setupPaths.m` in your project folder that adds MERIT, MERIT-EXT and the project itself to the path, starting from the location of the script:

```matlab
% setupPaths.m: adds MERIT and MERIT-EXT, found next to this project, to the path
here = fileparts(mfilename('fullpath'));
parent = fileparts(here);              % fileparts(fileparts(here)) for <parent>/projects/<project>
addpath(fullfile(parent, 'MERIT'));
addpath(fullfile(parent, 'MERIT-EXT'));
addpath(here);
which merit.process.delay
```

Change the current folder to your project and run `setupPaths` at the start of each session. The last command should print a path inside the MERIT folder. Add only the two root folders; do not add their subfolders with `genpath`, because package folders (those beginning with `+`) must not be on the path themselves. Only one MERIT folder may be on the path, since every MERIT version defines the package `merit`. Functions are then called with their package name, for example `signalvis.signalViewer` or `artefact.antennaNeighbours`.

## Data conventions

All functions follow MERIT's conventions:

- **Signals** are arrays with samples in dimension 1 and channels in dimension 2. A raw MERIT scan is complex, frequency samples x channels; a time-domain signal from `merit.process.fd2td` is real, time samples x channels.
- **Channel pairs** (`channel_names` in MERIT) are a C x 2 array: row c gives the transmitting (Tx) and receiving (Rx) antenna of signal column c.
- **Antenna locations** are an N x 3 array of x, y and z coordinates, in metres in the supplied data.
- **Imaging points** are a P x 3 array; the beamformer image returned by `merit.beamform` has one row per point.

Values that a real array cannot reveal, such as whether it holds a waveform, a magnitude in dB or a phase, are declared through options rather than inferred.

## A first session

Load the Galway phantom data from MERIT's `data` folder, which is found from the location of `merit.process.delay` on the path:

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
channel_names = dlmread(fullfile(dataRoot, 'channel_names.csv'));
antenna_locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));
```

Open the signal viewer on the original and rotated scans and their difference:

```matlab
[fig, viewer] = signalvis.signalViewer({scan1, scan2, scan1 - scan2}, frequencies, channel_names, ...
    'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');
```

Tick Tx and Rx antennas on the left, or single channels on the right, to choose the signals shown. The same choices can be made from a script through the returned `viewer`:

```matlab
viewer.SelectTx(1);
viewer.SelectRx([2 3]);
viewer.SetDisplay('Quantity', 'magnitude', 'MagnitudeScale', 'db');
```

Give each antenna a neighbourhood of the antennas within the default distance, here its two adjacent antennas in the same ring, and derive each channel's reference channels, whose average is subtracted from it in average subtraction:

```matlab
neighbours = artefact.antennaNeighbours(antenna_locations, channel_names);
references = artefact.referenceChannels(neighbours, channel_names);
```

`neighbours{i}` lists the neighbours of antenna *i*, and `references{c}` the reference channels of channel *c*. Passing `'References', references` to `signalViewer` lets you show a channel together with its reference channels.

## Functions return handles for scripting

Each interactive function returns the figure and a structure of functions that act on that figure, for example `[fig, viewer] = signalvis.signalViewer(...)`. The functions in the structure, such as `viewer.SelectTx` or `viewer.GetSelection`, do what the corresponding controls do, and they read or change only that figure. They are called through the returned variable, not through the package name, so several figures can be open and controlled independently. Assign the result of such a call before using its fields: write `s = viewer.GetSelection(); s.Tx`, because indexing directly into the result of the call (`viewer.GetSelection().Tx`) is not supported in every MATLAB release.

## Check the installation

The unit tests are `matlab.unittest` test classes in the packages `signalvis.test` and `artefact.test`. They use invisible figures:

```matlab
results = runtests({'signalvis.test', 'artefact.test'});
table(results)
```

Every test should pass. Mouse interaction cannot be tested by script.

## See Also

[Install MERIT-EXT and Run a First Example](installation.md) | [signalViewer](signalvis/signalViewer.md) | [inspectPointDelays](signalvis/inspectPointDelays.md) | [antennaNeighbours](artefact/antennaNeighbours.md) | [referenceChannels](artefact/referenceChannels.md) | [neighbourhoodEditor](artefact/neighbourhoodEditor.md)
