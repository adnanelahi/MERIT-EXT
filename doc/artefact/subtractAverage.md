# subtractAverage

Remove the artefact by subtracting the average of reference channels

Package: `artefact`

## Syntax

```matlab
cleaned = artefact.subtractAverage(signals, references)
cleaned = artefact.subtractAverage(___, 'Empty', mode)
[cleaned, info] = artefact.subtractAverage(___)
```

## Description

`cleaned = artefact.subtractAverage(signals, references)` subtracts from each channel *c* the mean of its reference channels:

```text
cleaned(:, c) = signals(:, c) - mean(signals(:, references{c}), 2)
```

The reference channels are those whose early-time artefact is expected to resemble that of channel *c*, as given by [referenceChannels](referenceChannels.md) or by the [neighbourhoodEditor](neighbourhoodEditor.md). Only one scan is needed, in contrast to rotation subtraction.

`cleaned = artefact.subtractAverage(___, 'Empty', mode)` sets what happens to a channel without reference channels.

`[cleaned, info] = artefact.subtractAverage(___)` also returns the channels without reference channels.

## Examples

### Remove the artefact from a Galway scan and image it

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
scan = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));

neighbours = artefact.antennaNeighbours(locations, pairs, 'Distance', 0.09);
references = artefact.referenceChannels(neighbours, pairs);
cleaned = artefact.subtractAverage(scan, references);

[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
delays = merit.beamform.get_delays(pairs, locations, 'relative_permittivity', 8);
img = abs(merit.beamform(cleaned, frequencies, points, delays, merit.beamformers.DAS));
```

### Compare the cleaned signal with the original

```matlab
signalvis.signalViewer({scan, cleaned}, frequencies, pairs, 'DatasetNames', {'Scan', 'Cleaned'}, ...
    'References', references, 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');
```

## Input Arguments

### `signals` — signals of one scan

numeric array

Samples x channels, as in MERIT: complex frequency-domain data, such as a raw scan, or real time-domain data. Further dimensions are processed in the same way. Because the operation is linear, subtracting in the frequency domain and converting to the time domain gives the same result as converting first.

### `references` — reference channels of each channel

C x 1 cell array | structure

The output of [referenceChannels](referenceChannels.md), or the structure returned by the `GetResult` function of [neighbourhoodEditor](neighbourhoodEditor.md).

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `Empty` | `'keep'`, `'zero'` | `'keep'` | For a channel without reference channels: leave it unchanged, or set it to zero. |

## Output Arguments

### `cleaned` — signals after subtraction

numeric array, the same size as `signals`

### `info` — channels without reference channels

structure with the field `NoReference`

## Tips

- The method assumes that the artefact is the same in a channel and in its reference channels, and that the tumour response is not. Whatever the reference channels share with the channel, including part of the tumour response, is removed as well.
- Including the channel in its own reference (`'IncludeSelf', true` in [referenceChannels](referenceChannels.md)) removes only part of its artefact, by a factor that depends on the number of reference channels.

## See Also

[referenceChannels](referenceChannels.md) | [antennaNeighbours](antennaNeighbours.md) | [neighbourhoodEditor](neighbourhoodEditor.md)
