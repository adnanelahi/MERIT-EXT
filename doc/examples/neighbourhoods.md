# Antenna Neighbourhoods and Reference Channels

Average subtraction removes the early-time artefact from a channel by subtracting a reference: the average of other channels whose artefact is expected to be similar. When an antenna transmits, receivers close together are expected to see a similar artefact from that transmission. This example gives each antenna of the Galway array a neighbourhood of nearby antennas, derives each channel's reference channels from it, and checks them against the signals; [subtractAverage](../artefact/subtractAverage.md) then performs the subtraction. The example assumes the path is set up as in [Getting Started](../getting-started.md).

## The array

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
```

The 24 antennas form three horizontal rings: antennas 1-10, 11-20 and 21-24, with the widest ring at the smallest z. The 96 channels are all pairs within a ring and none between rings, so each ring is measured as a separate set of channels.

## Neighbourhoods

```matlab
neighbours = artefact.antennaNeighbours(locations, pairs);
neighbours{1}                    % [2 10]
```

By default, the neighbours of an antenna are the antennas within a distance of it that share a measured channel with it. The default distance, 67.6 mm on this array, is 1.2 times the largest gap between an antenna and its nearest such antenna, so every antenna has its two adjacent antennas in its ring as neighbours. A distance can be given (`'Distance', 0.09`), or the k nearest antennas used instead (`'nearest', 'K', 2`); [antennaNeighbours](../artefact/antennaNeighbours.md) compares the two methods.

## Reference channels

```matlab
references = artefact.referenceChannels(neighbours, pairs);
c = find(pairs(:,1) == 1 & pairs(:,2) == 3);
pairs(references{c}, :)          % [1 2; 1 4]
```

By the receiver rule, the reference of channel 1-3 is the channels from transmitter 1 to the neighbours of receiver 3, which are antennas 2 and 4. By the transmitter rule (`'Rule', 'transmitter'`), it would be the channels from 1 to its own neighbours 2 and 10.

## Edit interactively

```matlab
[fig, editor] = artefact.neighbourhoodEditor(locations, pairs, 'DisplayCoordinateUnits', 'mm');
```

The editor starts with the same default neighbourhoods and draws the widest ring at the top. Choose an antenna to see its neighbours, press Edit neighbours and click antennas to change them, or apply a distance or k nearest to all antennas. Choose a channel in the channel list to see its reference channels. With the default distance, channels between adjacent antennas have a single reference channel; a distance of 90 mm gives larger reference sets.

## Check the references against the signals

```matlab
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
[~, viewer] = signalvis.signalViewer(scan1, frequencies, pairs, 'References', editor.GetResult(), ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');
viewer.ShowReference(c);
```

The viewer shows channel 1-3 with a thick line and its reference channels with normal lines, so that you can judge whether their early-time responses are alike.

## Keep the result

```matlab
result = editor.GetResult();
editor.Save('neighbourhoods.mat');
```

`result.References{c}` lists the reference channels of channel *c*; `result.History` records the operations that produced them.

## See Also

[antennaNeighbours](../artefact/antennaNeighbours.md) | [referenceChannels](../artefact/referenceChannels.md) | [neighbourhoodEditor](../artefact/neighbourhoodEditor.md) | [signalViewer](../signalvis/signalViewer.md)
