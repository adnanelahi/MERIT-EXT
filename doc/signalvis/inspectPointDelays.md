# inspectPointDelays

Compare original signals with the signals delayed for one imaging point

Package: `signalvis`

## Syntax

```matlab
signalvis.inspectPointDelays(signals, sampleAxis, points, delays)
signalvis.inspectPointDelays(___, Name, Value)
[fig, inspector] = signalvis.inspectPointDelays(___)
```

## Description

`signalvis.inspectPointDelays(signals, sampleAxis, points, delays)` opens a figure with a map of the imaging `points` on one z plane and, beside it, the original `signals` and the signals delayed for the selected point. Clicking the map selects the nearest point on the displayed plane; the delays for that point are evaluated and applied with MERIT's `merit.process.delay`, and both views are redrawn.

`signalvis.inspectPointDelays(___, Name, Value)` sets options, for example a beamformer image to colour the map, the units of the axes and delays, a window applied after the delay, or the channels shown.

`[fig, inspector] = signalvis.inspectPointDelays(___)` also returns the figure and a structure with functions for selecting a point or a plane and reading the current selection.

The function requires MERIT on the path, for `merit.process.delay`. It does not beamform; it shows the signals that the beamformer receives for one point.

## Examples

### Inspect a MERIT reconstruction

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
antennaLocations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
channelNames = dlmread(fullfile(dataRoot, 'channel_names.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));

channels = 1:8;
signals = scan1(:, channels) - scan2(:, channels);
channelPairs = channelNames(channels, :);
[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
delayFunction = merit.beamform.get_delays(channelPairs, antennaLocations, 'relative_permittivity', 8);
image = merit.beamform(signals, frequencies, points, delayFunction, merit.beamformers.DAS);

[fig, inspector] = signalvis.inspectPointDelays(signals, frequencies, points, delayFunction, ...
    'Image', image, 'Axes', axes_, 'SliceZ', 35e-3, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'MHz', 'DisplayCoordinateUnits', 'mm', ...
    'ChannelLabels', channelPairs);
```

The map shows the delay-and-sum image on the plane z = 35 mm. Click a bright region to see the signals delayed for that point. For frequency-domain data the delay changes the phase and leaves the magnitude unchanged, so compare the phase panels.

### Select points from a script

```matlab
inspector.SelectSlice(35e-3);      % nearest plane to z = 35 mm (CoordinateUnits)
inspector.SelectPoint(1234);       % global row of points
s = inspector.GetSelection();
s.DelaysSeconds                    % one delay per channel, in seconds
s.ImageValue                       % image value at the selected point
```

### Time-domain signals with precomputed sample delays and a window

```matlab
dt = 1e-9;
sampleAxis = (0:127)';
t = sampleAxis*dt;
signals = [sin(2*pi*35e6*t), cos(2*pi*22e6*t)];
points = [0 0 0; 1 0 0; 0 1 0; 1 1 0];
delaysSamples = [0 2 -1 3; 1 -2 0 2];           % C x P: one row per channel
window = @(x) x(9:120, :);                       % shortens the signals
signalvis.inspectPointDelays(signals, sampleAxis, points, delaysSamples, ...
    'Domain', 'time', 'AxisUnits', 'samples', 'SampleInterval', dt, ...
    'DelayUnits', 'samples', 'Window', window, 'WindowAxis', (8:119)', ...
    'Axes', {0:1, 0:1, 0});
```

A third column shows the delayed signals after the window. Because the window changes the number of samples, its sample coordinates are given by `WindowAxis`.

## Input Arguments

### `signals` — signals passed to the beamformer

numeric matrix

Samples x channels array, single or double: complex for frequency-domain data, real for time-domain data. MERIT chooses frequency or time processing from whether the array is real, so a complex time signal or a real spectrum is not supported. Select any further dimensions before calling.

### `sampleAxis` — sample coordinates

numeric vector

Finite, increasing vector with one value per sample: frequencies, times or sample numbers, in `AxisUnits`. A time axis must be uniformly spaced.

### `points` — imaging points

P x 3 numeric array

Unique, finite coordinates of the imaging points in `CoordinateUnits`, for example from `merit.domain.hemisphere`. For a planar domain use a constant z column. The row order is kept; point indices refer to rows.

### `delays` — delays for each point

function handle | numeric array

A function handle such as the one returned by `merit.beamform.get_delays`, called with one point in metres (1 x 3) and returning one delay per channel; or precomputed delays as a 1 x C x P or C x P array, or a vector of C delays when there is one point. The units are set by `DelayUnits`. MERIT's focusing delays are negative propagation times; they are used as given.

## Name-Value Arguments

Specify optional pairs of arguments as `Name1, Value1, ..., NameN, ValueN`.

### Data and units

| Name | Value | Default | Description |
|---|---|---|---|
| `Domain` | `'auto'`, `'time'`, `'frequency'` | `'auto'` | `'auto'` means frequency for frequency axis units and time otherwise. Time requires real signals; frequency requires complex signals. |
| `AxisUnits` | `'Hz'`, `'kHz'`, `'MHz'`, `'GHz'`, `'s'`, `'ms'`, `'us'`, `'ns'`, `'ps'`, `'samples'` | `'s'` for real signals, `'Hz'` for complex signals | Units of `sampleAxis`. |
| `DisplayAxisUnits` | units of the same kind | same as `AxisUnits` | Units of the displayed sample axis. Sample axes are displayed in samples. |
| `SampleInterval` | positive scalar, in seconds | none | Required when `AxisUnits` is `'samples'`. |
| `CoordinateUnits` | `'m'`, `'cm'`, `'mm'` | `'m'` | Units of `points`, `Axes` and `SliceZ`. Delay handles always receive metres. |
| `DisplayCoordinateUnits` | `'m'`, `'cm'`, `'mm'` | same as `CoordinateUnits` | Units of the map axes, map title and status line. |
| `DelayUnits` | `'s'`, `'ns'`, `'samples'` | `'s'` | Units of numeric delays or of the handle's output. `'samples'` requires time-domain data. |

### Map and selection

| Name | Value | Default | Description |
|---|---|---|---|
| `Image` | numeric array with P rows | none | The first output of `merit.beamform`, ordered like `points`; colours the map. Do not pass the raster returned by `get_slice`. |
| `ImageIndex` | vector | ones | Selects one image when `Image` has further dimensions (for example several delay models). |
| `ImageComponent` | `'auto'`, `'magnitude'`, `'real'`, `'imaginary'` | `'auto'` | Value mapped to colour; `'auto'` is the real value for real images and the magnitude for complex images. |
| `Axes` | `{xAxis, yAxis, zAxis}` | none | MERIT's axis vectors (second output of `merit.domain.hemisphere`), in `CoordinateUnits`. With a regular grid and an image, the selected plane is shown as a raster, with points outside the domain left blank. |
| `SliceZ` | scalar | first plane | Initial z, in `CoordinateUnits`; the nearest plane is used. |
| `InitialPoint` | point index | first point on the initial plane | Initial selected point. |

### Window

| Name | Value | Default | Description |
|---|---|---|---|
| `Window` | function handle | none | Applied to the delayed samples x channels matrix, as MERIT's `beamform` does before the beamformer; its output is shown in a third column. It must keep the number of channels. |
| `WindowAxis` | increasing vector | `sampleAxis` | Sample coordinates of the window output, in `AxisUnits`. Required when the window changes the number of samples. |

### Signal display

| Name | Value | Default | Description |
|---|---|---|---|
| `Channels` | vector of column numbers | all | Channels shown, in the given order. |
| `ChannelLabels` | C x 2 antenna pairs, or one text label per channel | `'Channel 1'`, ... | Labels; pairs are shown as (Tx, Rx). |
| `TraceLabels` | one text label per channel | none | Replaces `ChannelLabels`. |
| `Quantity` | `'auto'`, `'value'`, `'magnitude'`, `'phase'`, `'both'` | `'value'` for real, `'both'` for complex | Quantity plotted. |
| `MagnitudeScale` | `'linear'`, `'db'` | `'linear'` | Magnitude scale. |
| `DBFloor` | scalar | `-300` | Lowest dB value shown for small magnitudes. |
| `PhaseUnits` | `'radians'`, `'degrees'` | `'radians'` | Phase units. |
| `UnwrapPhase` | logical scalar | `false` | Unwrap phases along the samples. |
| `Layout` | `'overlay'`, `'individual'` | `'overlay'` | All channels on one axes per quantity, or one row per channel in pages. |
| `ChannelsPerPage` | positive integer | `4` | Channels per page in the individual layout. |
| `Legend` | `'auto'`, `'on'`, `'off'` | `'auto'` | Legend display; `'auto'` shows it for 12 or fewer channels. |
| `Title` | character vector | none | Prefix for the panel titles. |
| `Visible` | `'on'`, `'off'` | `'on'` | Figure visibility. |

## Output Arguments

### `fig` — figure

Figure handle.

### `inspector` — functions that act on the figure

structure

| Field | Description |
|---|---|
| `SelectPoint(index)` | Select a point by its row in `points`, changing plane if necessary. |
| `SelectSlice(z)` | Select the plane nearest to z (in `CoordinateUnits`) and its first point. |
| `GetSelection()` | Current selection, described below. |

The structure also contains the handles `MapAxes`, `OriginalAxes`, `DelayedAxes`, `WindowedAxes`, `SliceControl`, `PreviousPage`, `NextPage`, `PageText` and `Status`.

`GetSelection` returns a structure with the fields `PointIndex`, `Point` (in `CoordinateUnits`), `PointMetres`, `SliceZ`, `Domain`, `DelaysSeconds` (1 x C), `CalculationAxis` (in hertz or seconds), `OriginalSignals`, `DelayedSignals` (before the window), `ComparedSignals` (after the window, or equal to `DelayedSignals`), `ComparedAxis`, `Channels`, `Page`, `ImageValue`, `CoordinateUnits`, `DisplayCoordinateUnits`, `AxisUnits`, `DisplayAxisUnits`, `DelayUnits` and `SampleInterval`. Signals are samples x channels.

## Tips

- **Frequency-domain delays change the phase only.** MERIT multiplies each spectrum by exp(-2j*pi*f*delay), so the magnitudes before and after the delay are identical; compare the phases.
- **Time-domain delays are whole samples.** MERIT shifts by round(delay/dt) samples and fills the vacated samples with NaN, which appear as gaps; there is no fractional interpolation.
- **Use the signals given to the beamformer.** Pass the same processed signals that were passed to `merit.beamform`, for example the rotation-subtracted scans, so that the comparison shows what the beamformer received.
- **Errors from clicks.** If a click cannot be processed, the status line gives the reason and the previous selection is kept; the functions in `inspector` raise errors instead.

## See Also

[signalViewer](signalViewer.md) | [Getting Started](../getting-started.md)
