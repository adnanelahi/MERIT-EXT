# signalViewer

Choose interactively which channel signals to display and compare

Package: `signalvis`

## Syntax

```matlab
signalvis.signalViewer(signals, sampleAxis, channelPairs)
signalvis.signalViewer(___, Name, Value)
[fig, viewer] = signalvis.signalViewer(___)
```

## Description

`signalvis.signalViewer(signals, sampleAxis, channelPairs)` opens a figure that displays the columns of `signals` against `sampleAxis`. Signals are chosen by ticking transmitting (Tx) and receiving (Rx) antennas, taken from `channelPairs`, or by ticking single channels. At the start all channels are shown.

`signalvis.signalViewer(___, Name, Value)` sets options, for example the type of the input data, the units of the sample axis, reference channels to show with a chosen channel, or the initial display.

`[fig, viewer] = signalvis.signalViewer(___)` also returns the figure and a structure of functions that select signals and change the display from a script.

The figure contains:

- **Tx antennas** and **Rx antennas** (left): ticking antennas shows exactly the channels whose Tx and Rx are both ticked.
- **Channel and its reference channels** (left, with the `References` option): choosing a channel shows it, drawn with a thicker line, together with its reference channels, and ticks their Tx and Rx antennas.
- **Datasets** (left, when several arrays are supplied): ticking chooses which datasets are drawn; the table also gives each dataset's line style.
- **Channels** (right): every channel, labelled Tx-Rx; ticking or unticking changes only that channel and leaves the Tx and Rx ticks as they are.
- **Display controls** (top): quantity, magnitude scale, phase units, phase unwrapping and layout.
- **Plot** (centre): updated after every change, with a status line below it and, in the individual layout, page controls.

## Examples

### Compare three datasets for one transmitter

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
f = dlmread(fullfile(dataRoot, 'frequencies.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));

[fig, viewer] = signalvis.signalViewer({scan1, scan2, scan1 - scan2}, f, pairs, ...
    'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'InitialTx', 1, 'InitialRx', [2 3]);
```

The figure shows channels 1-2 and 1-3 of all three datasets. Each channel keeps one colour, and the datasets are drawn solid, dashed and dotted.

### Display already converted magnitude and phase

MERIT's getting-started script stores magnitudes in dB and phases already unwrapped. Declare their types so that they are displayed as supplied:

```matlab
magnitudeDb = 20*log10(abs(scan1));
phaseUnwrapped = unwrap(angle(scan1));
signalvis.signalViewer({magnitudeDb, phaseUnwrapped}, f, pairs, ...
    'InputType', {'magnitude', 'phase'}, 'InputMagnitudeScale', {'dB', 'linear'}, ...
    'DatasetNames', {'Magnitude', 'Unwrapped phase'}, 'Quantity', 'both', ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');
```

The magnitude dataset appears on the magnitude axes only and the phase dataset on the phase axes only.

### Select signals from a script and read what is shown

```matlab
viewer.SelectTx(5);
viewer.SelectRx(6:10);
viewer.SetDisplay('Quantity', 'magnitude', 'MagnitudeScale', 'db', 'Layout', 'individual');
selection = viewer.GetSelection();
selection.ChannelLabels
lines = viewer.GetDisplayedData();
plot(lines(1).X, lines(1).Y)
```

### View real time-domain waveforms

```matlab
t = (0:0.02:6)'*1e-9;
w = [exp(-((t-2e-9)/0.3e-9).^2), exp(-((t-3e-9)/0.3e-9).^2)];
signalvis.signalViewer(w, t, [1 2; 1 3], 'AxisUnits', 's', 'DisplayAxisUnits', 'ns');
```

Real data is treated as a waveform unless another `InputType` is given; the quantity menu offers its value and its magnitude.

## Input Arguments

### `signals` — signals to display

numeric matrix | cell array of numeric matrices

Samples x channels array of type single or double, or a cell array of such arrays with the same size, one per dataset. Several datasets must have the same channels in the same column order, for example an original scan, a rotated scan and their difference. Non-finite values are shown as gaps.

### `sampleAxis` — sample coordinates

numeric vector | `[]`

Finite real vector with one value per sample, for example MERIT's `frequencies`. With `[]`, samples are numbered 1, 2, 3 and so on. The units are set by `AxisUnits`.

### `channelPairs` — Tx and Rx antenna of each channel

C x 2 numeric array | `[]`

MERIT's `channel_names` array: row c gives the transmitting and receiving antenna of column c of `signals`. With `[]`, channels are labelled Channel 1, Channel 2 and so on, and selection is by channel only.

## Name-Value Arguments

Specify optional pairs of arguments as `Name1, Value1, ..., NameN, ValueN`. Names are not case sensitive. Text values that apply per dataset may be given once for all datasets or as a cell array with one entry per dataset.

### Input data

| Name | Value | Default | Description |
|---|---|---|---|
| `InputType` | `'auto'`, `'complex'`, `'waveform'`, `'magnitude'`, `'phase'` | `'auto'` | What the values are. `'auto'` means `'complex'` for non-real data and `'waveform'` for real data. Real data holding a magnitude or a phase must be declared, because the values cannot reveal it. |
| `InputMagnitudeScale` | `'linear'`, `'dB'` | `'linear'` | Scale of `'magnitude'` input. Linear magnitudes must be nonnegative. |
| `InputPhaseUnits` | `'radians'`, `'degrees'` | `'radians'` | Units of `'phase'` input. |
| `DatasetNames` | cell array of character vectors | `'Signals'`, or `'Dataset 1'`, `'Dataset 2'`, ... | One name per dataset, used in the dataset table and the legends. |

### Sample axis

| Name | Value | Default | Description |
|---|---|---|---|
| `AxisUnits` | `'samples'`, `'Hz'`, `'kHz'`, `'MHz'`, `'GHz'`, `'s'`, `'ms'`, `'us'`, `'ns'`, `'ps'` | `'samples'` without `sampleAxis`; otherwise none (the axis is labelled "Sample axis") | Units of `sampleAxis`. |
| `DisplayAxisUnits` | units of the same kind as `AxisUnits` | same as `AxisUnits` | Units in which the axis is displayed, for example `'GHz'` for frequencies supplied in hertz. |

### Selection

| Name | Value | Default | Description |
|---|---|---|---|
| `References` | C x 1 cell array from `artefact.referenceChannels`, or the structure from `artefact.neighbourhoodEditor` (`GetResult`) | none | Reference channels of each channel; adds the choice of a channel to show with its reference channels. |
| `InitialTx` | vector of antenna numbers | all Tx antennas | Tx antennas ticked at the start. |
| `InitialRx` | vector of antenna numbers | all Rx antennas | Rx antennas ticked at the start. |

### Display

| Name | Value | Default | Description |
|---|---|---|---|
| `Quantity` | `'magnitude'`, `'phase'`, `'both'`, `'value'`, `'real'`, `'imaginary'` | `'both'` for complex, `'value'` for waveform, otherwise the input type of the first dataset | Quantity plotted. Only quantities that at least one dataset can provide are allowed (see Tips). |
| `MagnitudeScale` | `'linear'`, `'db'` | `'linear'`; `'db'` if the first dataset is a dB magnitude | Display scale of magnitudes. A zero magnitude in dB is shown as a gap. |
| `PhaseUnits` | `'radians'`, `'degrees'` | `'radians'`; the input units if the first dataset is a phase | Display units of phases. |
| `UnwrapPhase` | `true`, `false` | `false` | Unwrap phases along the samples, separately within each run of finite samples. |
| `Layout` | `'overlay'`, `'individual'` | `'overlay'` | `'overlay'` draws all chosen signals on one axes per quantity; `'individual'` draws one row of panels per channel, in pages. |
| `ChannelsPerPage` | positive integer | `6` | Channels per page in the individual layout. |
| `Title` | character vector | `'Selected signals'` | Title above the overlay plot. |
| `Visible` | `'on'`, `'off'` | `'on'` | Figure visibility. |

## Output Arguments

### `fig` — figure

Figure handle.

### `viewer` — functions that act on the figure

structure

Fields that are functions do what the corresponding controls do and act only on this figure. They remain usable after the figure is closed, without drawing.

| Field | Description |
|---|---|
| `SelectTx(antennas)` | Tick these Tx antennas (only these) and show the matching channels. `[]` unticks all. |
| `SelectRx(antennas)` | Tick these Rx antennas and show the matching channels. |
| `SelectChannels(indices)` | Show these channels, given as column numbers of `signals`. The Tx and Rx ticks are unchanged. |
| `ShowReference(c)` | Show channel *c*, drawn thicker, with its reference channels, and tick their Tx and Rx antennas; `0` clears the choice. |
| `SelectDatasets(indices)` | Show these datasets. |
| `SetDisplay(Name, Value, ...)` | Change `Quantity`, `MagnitudeScale`, `PhaseUnits`, `UnwrapPhase`, `Layout`, `ChannelsPerPage` or `Page`. Invalid values raise an error and leave the display unchanged. |
| `GetSelection()` | Structure with fields `Tx`, `Rx`, `Channels`, `ChannelLabels`, `ReferenceFor` (the channel chosen with `ShowReference`, or 0), `Datasets`, `DatasetNames`, `Quantity`, `MagnitudeScale`, `PhaseUnits`, `UnwrapPhase`, `Layout`, `Page` and `Pages`. |
| `GetDisplayedData()` | Structure array with one element per plotted line and fields `Quantity`, `QuantityLabel`, `Dataset`, `DatasetName`, `Channel`, `Tx`, `Rx`, `Label`, `Highlighted` (true for the channel chosen with `ShowReference`), `X` and `Y`. In the individual layout only the lines on the current page are returned. |

The structure also contains the handles `Figure`, `PlotPanel`, `TxTable`, `RxTable`, `ChannelTable`, `ReferencePopup`, `DatasetTable`, `QuantityPopup` and `Status`.

## Tips

- **Quantities per input type.** Complex data provides magnitude, phase, real part and imaginary part; a waveform provides its value and its magnitude (absolute value); a magnitude provides magnitude; a phase provides phase. With several datasets of different types, a dataset that cannot provide the selected quantity is not drawn, and the status line names it. Phase is never derived from a magnitude, nor magnitude from a phase.
- **Strict Tx and Rx matching.** Channel (a, b) is shown when a is ticked as Tx and b as Rx. MERIT lists each antenna pair once, with the lower antenna number as Tx, so in the Galway data antennas 10, 20 and 24 never appear as Tx and antennas 1, 11 and 21 never appear as Rx.
- **Pages.** A new Tx, Rx, channel or reference selection returns the individual layout to its first page.
- **Window size.** The window opens at 92 % x 86 % of the screen, and panels, lists and plots scale with it; table columns follow the table widths. Font sizes are MATLAB's defaults.
- **Results of `viewer` functions.** Assign the result before using its fields: `s = viewer.GetSelection(); s.Tx`. Indexing directly into the result of the call is not supported in every MATLAB release.

## See Also

[inspectPointDelays](inspectPointDelays.md) | [referenceChannels](../artefact/referenceChannels.md) | [Getting Started](../getting-started.md) | [Compare Original, Rotated and Rotation-Subtracted Scans](../examples/compare-scans.md)
