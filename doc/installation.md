# Install MERIT-Extensions and Run a First Example

This page takes you from an empty folder to a working installation: cloning MERIT and MERIT-Extensions, adding them to the MATLAB path, checking the installation and running the first examples. [Getting Started](getting-started.md) then explains the data conventions and how to use the packages in your own code.

## 1. Requirements

- **MATLAB.** No additional toolboxes are needed.
- **Git**, to clone the repositories (`git --version` in a terminal should print a version number). On Windows, Git for Windows provides it.
- Access to the MERIT-Extensions repository on GitHub, which is currently private; ask the author for access.

**Tested with:** MATLAB R2018a and MERIT commit `03ea497` (4 July 2019), which step 4 checks out. Later MERIT commits use syntax that requires a newer MATLAB release and have not been tested with these packages.

## 2. Choose a folder

Create or choose a parent folder for both projects, for example `C:\work\merit` or `~/merit`. The commands below are run in this folder and produce this layout:

```text
<parent>/
  MERIT-Extensions/   % this project
  MERIT/              % MERIT, including its data folder
```

The two folders can also be placed elsewhere: the examples and checks find MERIT, and its example data, through the MATLAB path.

Avoid a folder that is synchronised by a cloud service such as OneDrive or Dropbox: synchronising a live `.git` folder can corrupt the repository.

## 3. Clone MERIT-Extensions

In a terminal, in the parent folder:

```bash
git clone https://github.com/adnanelahi/MERIT-Extensions.git
```

This creates the folder `MERIT-Extensions` with the packages `+signalvis` and `+artefact` and the `examples`, `verification` and `doc` folders.

## 4. Clone MERIT

In the same parent folder:

```bash
git clone https://github.com/EMFMed/MERIT.git
cd MERIT
git checkout -b tested 03ea4972205d6f68f8a666172c6f6b14ca08fa31
cd ..
```

The `git checkout` line creates a local branch, `tested`, at the commit with which the packages were tested (see Requirements). The folder `MERIT/data` contains the Galway phantom measurements used by the examples (Oliveira et al. 2018): frequencies, antenna locations, channel pairs and scans.

MERIT is licensed under Apache 2.0. If you use it, cite D. O'Loughlin, M. A. Elahi, E. Porter et al., "Open-source software for microwave radar-based image reconstruction," Proc. 12th European Conference on Antennas and Propagation (EuCAP), London, 2018.

## 5. Add the folders to the MATLAB path

Start MATLAB and change the current folder to `MERIT-Extensions`, for example with `cd('C:\work\merit\MERIT-Extensions')`. Then run:

```matlab
addpath(pwd);
addpath(fullfile(fileparts(pwd), 'MERIT'));
```

Add these two root folders only. Do not use `genpath` or the "Add with Subfolders" button: the packages are the folders beginning with `+`, and MATLAB finds them through their parent folder. Every MERIT version defines the package `merit`, so if another MERIT folder is already on the path, remove it first (Home > Set Path, or `rmpath`).

The path lasts until MATLAB is closed. To restore it automatically, put the two `addpath` lines, with full folder names, in a `startup.m` file in your MATLAB user folder (`userpath` shows where it is).

## 6. Check the installation

```matlab
which merit.process.delay
help signalvis
help artefact
```

`which` should print a path inside your `MERIT` folder, ending in `+merit\+process\delay.m` (or with `/` on macOS and Linux). `help signalvis` and `help artefact` should list the functions of each package.

Then run the scripted checks, which take a few minutes and draw only invisible figures:

```matlab
addpath(fullfile(pwd, 'verification'));
verify_signal_viewer();
verify_point_inspector();
verify_neighbourhoods();
```

Each check prints a line beginning `PASS:` or `FAIL:`. A function that finishes without an error means that all its checks passed; any failure ends with an error message.

## 7. Run the first examples

The `examples` folder contains scripts that run on the Galway data. Start with the signal viewer:

```matlab
run(fullfile('examples', 'viewMeritSignals.m'));
```

Two windows open. The first compares the original, rotated and rotation-subtracted scans for channels 1-2 and 1-3. Tick other Tx and Rx antennas on the left, or single channels on the right, and change the quantity or layout at the top; the plot follows each change. The second window shows a magnitude in dB and an unwrapped phase that were computed beforehand.

Then the antenna neighbourhoods:

```matlab
run(fullfile('examples', 'meritNeighbourhoods.m'));
```

The editor window shows the 24 antennas in three rings, each with its two nearest antennas as neighbours. Choose an antenna to see its neighbours, press Edit neighbours and click antennas to change them, and choose a channel to see its reference channels. A signal viewer also opens, showing channel 1-3 with its reference channels.

The other examples are `viewSyntheticSignals.m` (real time-domain waveforms, without MERIT data), `inspectMeritImage.m` (signals delayed for a point chosen on a delay-and-sum image) and `inspectSyntheticTime.m` (the same with synthetic data).

## 8. Use the packages in your own code

With the path set, the functions are called with their package name:

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
channel_names = dlmread(fullfile(dataRoot, 'channel_names.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));

[fig, viewer] = signalvis.signalViewer(scan1, frequencies, channel_names, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');
viewer.SelectTx(1);
```

The first line finds MERIT's `data` folder from the location of `merit.process.delay` on the path. Continue with [Getting Started](getting-started.md) for the data conventions and with the [function reference](README.md) for every option.

## 9. Update

To obtain the latest version of MERIT-Extensions, run in its folder:

```bash
git pull
```

Keep MERIT on the `tested` branch unless you have checked a later MERIT commit with your MATLAB release.

## Troubleshooting

| Message or symptom | Cause and remedy |
|---|---|
| MATLAB reports that `signalvis` or `artefact` is undefined or cannot be resolved | `MERIT-Extensions` is not on the path and is not the current folder; repeat step 5. Add the `MERIT-Extensions` folder itself, not `+signalvis`. |
| `MERIT's merit.process.delay must be on the MATLAB path.` or `Add the MERIT folder to the MATLAB path before running this example.` | MERIT is not on the path; repeat step 5. |
| `which merit.process.delay` shows a folder other than your `MERIT` folder | Another MERIT folder is on the path; remove it with `rmpath` and add yours. |
| `Error using dlmread ... could not be opened` | The MERIT folder on the path has no `data` folder with the Galway files; check that it is a complete clone. |
| Errors inside `+merit` functions | A MERIT commit other than the tested one may be in use; repeat the checkout in step 4. |
| `Invalid text character` at line 1, column 1 of a file you edited | Some MATLAB releases cannot read a file saved with a UTF-8 byte-order mark; save it as UTF-8 without BOM. |
| Tables or lists in a window do not visibly update | Move the pointer over the table; on some systems tables repaint late. |

## See Also

[Getting Started](getting-started.md) | [Documentation index](README.md)
