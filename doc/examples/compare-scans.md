# Compare Original, Rotated and Rotation-Subtracted Scans

This example uses `signalvis.signalViewer` to compare, channel by channel, the two scans of the Galway phantom data and their difference, which removes the early-time artefact by rotation subtraction. It assumes the path is set up as in [Getting Started](../getting-started.md).

## Load the data

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
channel_names = dlmread(fullfile(dataRoot, 'channel_names.csv'));
antenna_locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));   % original position
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));   % rotated by 36 degrees
```

Each scan is a 76 x 96 complex array: 76 frequencies from 1.5 to 4.5 GHz and 96 channels. Row c of `channel_names` gives the transmitting and receiving antenna of channel c.

## Open the viewer

```matlab
neighbours = artefact.antennaNeighbours(antenna_locations, channel_names, 'nearest', 'K', 2);
references = artefact.referenceChannels(neighbours, channel_names);
[fig, viewer] = signalvis.signalViewer({scan1, scan2, scan1 - scan2}, frequencies, channel_names, ...
    'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, 'References', references, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'InitialTx', 1, 'InitialRx', [2 3]);
```

The viewer shows channels 1-2 and 1-3. In the magnitude plot the original (solid) and rotated (dashed) scans almost coincide, because the early-time artefact dominates both; the subtracted signal (dotted) is much smaller.

## Choose signals

- Tick Tx 5 and untick the others to see every channel transmitted by antenna 5; the Rx ticks decide which of those are shown.
- Choose a channel under "Channel and its reference channels" to see it, drawn thicker, with its reference channels.
- Untick single channels in the channel list on the right to remove them from the plot.
- Untick a dataset to hide it.

The same selections from a script:

```matlab
viewer.SelectTx(5);
viewer.ShowReference(10);        % channel 1-3 and its reference channels
viewer.SelectDatasets([1 3]);
```

## Change the display

Choose Magnitude and dB in the menus, or:

```matlab
viewer.SetDisplay('Quantity', 'magnitude', 'MagnitudeScale', 'db', 'Layout', 'individual');
```

The individual layout shows one row per channel, six channels per page, with Previous and Next buttons when more channels are selected.

## Use the selection

```matlab
s = viewer.GetSelection();
s.ChannelLabels                 % channels shown, as 'Tx-Rx'
lines = viewer.GetDisplayedData();
[lines.Channel]                 % channel of each plotted line
```

`GetDisplayedData` returns the plotted values, so a selection made by hand can be taken into further analysis.

## See Also

[signalViewer](../signalvis/signalViewer.md) | [referenceChannels](../artefact/referenceChannels.md)
