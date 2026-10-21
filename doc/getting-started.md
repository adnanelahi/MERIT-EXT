# Getting Started with MERIT-EXT

MERIT-EXT is a set of MATLAB packages that extend the MERIT microwave imaging toolbox. `signalvis` displays and compares the signals of antenna channels; `artefact` forms antenna neighbourhoods and reference channels for removing the early-time artefact. The code is intended for eventual integration into MERIT.

This page takes you from an empty folder to a working installation and a first session: choosing a folder layout, cloning MERIT and MERIT-EXT, setting the path, checking the installation, running the examples, and using the packages in your own code.

## Requirements

- **MATLAB**, with no additional toolboxes. `signalvis.signalViewer` and all `artefact` functions use base MATLAB only.
- **MERIT** on the MATLAB path, for `signalvis.inspectPointDelays`, which calls `merit.process.delay`, and for the examples, which use the Galway phantom data in MERIT's `data` folder.
- **Git**, to clone the repositories (`git --version` in a terminal should print a version number). On Windows, Git for Windows provides it.
- Access to the MERIT-EXT repository on GitHub, which is currently private; ask the author for access.

**Tested with:** MATLAB R2018a and MERIT commit `03ea497` (4 July 2019), which [Clone MERIT and MERIT-EXT](#clone-merit-and-merit-ext) checks out. Later MERIT commits use syntax that requires a newer MATLAB release and have not been tested with these packages.

## Folder layout

Create or choose a parent folder for MERIT, MERIT-EXT and your own code, for example `C:\work\merit` or `~/merit`, and keep the three in separate folders under it. Your own code can lie next to MERIT and MERIT-EXT or in a subfolder of the parent folder:

```text
<parent>/
  MERIT/              % MERIT, including its data folder; unchanged
  MERIT-EXT/          % MERIT-EXT; unchanged
  my-project/         % your own scripts and functions
  projects/           % or several projects in a subfolder
    another-project/
```

Develop in your own folder and leave the MERIT and MERIT-EXT folders unchanged. They can then be updated with `git pull` without conflicts with your files, and your project can be versioned in a repository of its own. A new function meant for one of the packages, such as an artefact-removal method for `artefact`, is also written in your own folder, as [Extending MERIT and MERIT-EXT](extending.md) describes.

The parent folder itself should be a plain folder, not a git repository. Avoid a folder that is synchronised by a cloud service such as OneDrive or Dropbox: synchronising a live `.git` folder can corrupt the repository.

## Clone MERIT and MERIT-EXT

In a terminal, in the parent folder:

```bash
git clone https://github.com/adnanelahi/MERIT-EXT.git
git clone https://github.com/EMFMed/MERIT.git
cd MERIT
git checkout -b tested 03ea4972205d6f68f8a666172c6f6b14ca08fa31
cd ..
```

The first command creates the folder `MERIT-EXT` with the packages `+signalvis` and `+artefact`, which include their unit tests, and the `examples` and `doc` folders. The second creates the folder `MERIT`. The `git checkout` line creates a local branch of MERIT, `tested`, at the commit with which the packages were tested (see [Requirements](#requirements)), and `cd ..` returns to the parent folder. The folder `MERIT/data` contains the Galway phantom measurements used by the examples (Oliveira et al. 2018): frequencies, antenna locations, channel pairs and scans.

MERIT is licensed under Apache 2.0. If you use it, cite D. O'Loughlin, M. A. Elahi, E. Porter et al., "Open-source software for microwave radar-based image reconstruction," Proc. 12th European Conference on Antennas and Propagation (EuCAP), London, 2018.

## Set up the path

Create the folder for your own code, for example `<parent>/my-project`, and save in it a script `setupPaths.m` that adds MERIT, MERIT-EXT and the project itself to the path, starting from the location of the script, so that it works on any computer with the same layout:

```matlab
% setupPaths.m: adds MERIT and MERIT-EXT, found next to this project, to the path
here = fileparts(mfilename('fullpath'));
parent = fileparts(here);              % fileparts(fileparts(here)) for <parent>/projects/<project>
addpath(fullfile(parent, 'MERIT'));
addpath(fullfile(parent, 'MERIT-EXT'));
addpath(here);
which merit.process.delay
```

Start MATLAB, change the current folder to `my-project` and run `setupPaths`; do this at the start of each session. If the project lies in a subfolder such as `<parent>/projects/my-project`, the parent folder is two levels up, as the comment in the script notes. The script leaves the variable `parent` in the workspace, which the commands below use.

Add only the MERIT and MERIT-EXT root folders. Do not use `genpath` or the "Add with Subfolders" button: the packages are the folders beginning with `+`, and MATLAB finds them through their parent folder. Every MERIT version defines the package `merit`, so if another MERIT folder is already on the path, remove it first (Home > Set Path, or `rmpath`). Alternatively to `setupPaths`, the `addpath` lines, with full folder names, can be put in a `startup.m` file in your MATLAB user folder (`userpath` shows where it is), which MATLAB runs when it starts.

## Check the installation

```matlab
which merit.process.delay
help signalvis
help artefact
```

`which` should print a path inside your `MERIT` folder, ending in `+merit\+process\delay.m` (or with `/` on macOS and Linux). `help signalvis` and `help artefact` should list the functions of each package.

Then run the unit tests, which take a few minutes and draw only invisible figures:

```matlab
results = runtests({'signalvis.test', 'artefact.test'});
table(results)
```

The table lists each test with `Passed`, `Failed` and `Incomplete`; all 36 tests should pass. The tests are `matlab.unittest` test classes, as in MERIT, in the packages `signalvis.test` and `artefact.test`. Mouse interaction cannot be tested by script.

## Run the examples

The `examples` folder of MERIT-EXT contains scripts that run on the Galway data. Start with the signal viewer:

```matlab
run(fullfile(parent, 'MERIT-EXT', 'examples', 'viewMeritSignals.m'));
```

Two windows open. The first compares the original, rotated and rotation-subtracted scans for channels 1-2 and 1-3. Tick other Tx and Rx antennas on the left, or single channels on the right, and change the quantity or layout at the top; the plot follows each change. The second window shows a magnitude in dB and an unwrapped phase that were computed beforehand.

Then the antenna neighbourhoods:

```matlab
run(fullfile(parent, 'MERIT-EXT', 'examples', 'meritNeighbourhoods.m'));
```

The editor window shows the 24 antennas in three rings around the imaging domain, a hemisphere of 7 cm radius drawn as a transparent surface, each antenna with the antennas within the default distance, here its two adjacent antennas, as neighbours. Choose an antenna to see its neighbours, press Edit neighbours and click antennas to change them, and choose a channel to see its reference channels. A signal viewer also opens, showing channel 1-3 with its reference channels.

The other examples are `viewSyntheticSignals.m` (real time-domain waveforms, without MERIT data), `inspectMeritImage.m` (signals delayed for a point chosen on a delay-and-sum image) and `inspectSyntheticTime.m` (the same with synthetic data).

## Data conventions

All functions follow MERIT's conventions:

- **Signals** are arrays with samples in dimension 1 and channels in dimension 2. A raw MERIT scan is complex, frequency samples x channels; a time-domain signal from `merit.process.fd2td` is real, time samples x channels.
- **Channel pairs** (`channel_names` in MERIT) are a C x 2 array: row c gives the transmitting (Tx) and receiving (Rx) antenna of signal column c.
- **Antenna locations** are an N x 3 array of x, y and z coordinates, in metres in the supplied data.
- **Imaging points** are a P x 3 array; the beamformer image returned by `merit.beamform` has one row per point.

Values that a real array cannot reveal, such as whether it holds a waveform, a magnitude in dB or a phase, are declared through options rather than inferred.

## A first session

Your own scripts are kept in your project folder, and the functions of MERIT and MERIT-EXT are called with their package name. Load the Galway phantom data from MERIT's `data` folder, which is found from the location of `merit.process.delay` on the path:

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

`neighbours{i}` lists the neighbours of antenna *i*, and `references{c}` the reference channels of channel *c*. Passing `'References', references` to `signalViewer` lets you show a channel together with its reference channels. The [tutorial](tutorials/average-subtraction-pipeline.md) continues from here to a complete processing script, from the measured scans to an image.

## Functions return handles for scripting

Each interactive function returns the figure and a structure of functions that act on that figure, for example `[fig, viewer] = signalvis.signalViewer(...)`. The functions in the structure, such as `viewer.SelectTx` or `viewer.GetSelection`, do what the corresponding controls do, and they read or change only that figure. They are called through the returned variable, not through the package name, so several figures can be open and controlled independently. Assign the result of such a call before using its fields: write `s = viewer.GetSelection(); s.Tx`, because indexing directly into the result of the call (`viewer.GetSelection().Tx`) is not supported in every MATLAB release.

## Update

To obtain the latest version of MERIT-EXT, run in its folder:

```bash
git pull
```

Because your own code is kept in a separate folder, the update does not touch it.

## Troubleshooting

| Message or symptom | Cause and remedy |
|---|---|
| MATLAB reports that `signalvis` or `artefact` is undefined or cannot be resolved | `MERIT-EXT` is not on the path; run `setupPaths` in your project folder (see [Set up the path](#set-up-the-path)). Add the `MERIT-EXT` folder itself, not `+signalvis`. |
| `MERIT's merit.process.delay must be on the MATLAB path.` or `Add the MERIT folder to the MATLAB path before running this example.` | MERIT is not on the path; run `setupPaths`, and check that the MERIT folder is named `MERIT` and lies in the parent folder. |
| `which merit.process.delay` shows a folder other than your `MERIT` folder | Another MERIT folder is on the path; remove it with `rmpath` and add yours. |
| `Undefined function or variable 'parent'` when running an example | `setupPaths` has not been run in this session, or the workspace was cleared; run it again. |
| `fatal: destination path ... already exists and is not an empty directory` when cloning | A folder with that name already exists in the parent folder, for example from an earlier attempt; delete it or clone in another parent folder. |
| `Error using dlmread ... could not be opened` | The MERIT folder on the path has no `data` folder with the Galway files; check that it is a complete clone. |
| Errors inside `+merit` functions | A MERIT commit other than the tested one may be in use; repeat the `git checkout` in [Clone MERIT and MERIT-EXT](#clone-merit-and-merit-ext). |
| `Invalid text character` at line 1, column 1 of a file you edited | Some MATLAB releases cannot read a file saved with a UTF-8 byte-order mark; save it as UTF-8 without BOM. |
| Tables or lists in a window do not visibly update | Move the pointer over the table; on some systems tables repaint late. |

## See Also

[Documentation index](README.md) | [Tutorial](tutorials/average-subtraction-pipeline.md) | [Extending MERIT and MERIT-EXT](extending.md) | [signalViewer](signalvis/signalViewer.md) | [inspectPointDelays](signalvis/inspectPointDelays.md) | [antennaNeighbours](artefact/antennaNeighbours.md) | [referenceChannels](artefact/referenceChannels.md) | [neighbourhoodEditor](artefact/neighbourhoodEditor.md)
