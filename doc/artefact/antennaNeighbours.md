# antennaNeighbours

Neighbourhood of each antenna from the antenna positions

Package: `artefact`

## Syntax

```matlab
neighbours = artefact.antennaNeighbours(locations, channelPairs, method, Name, Value)
```

## Description

`neighbours = artefact.antennaNeighbours(locations, channelPairs, method, Name, Value)` gives every antenna its own neighbourhood: the *k* antennas nearest to it (`method` `'nearest'`) or all antennas within a distance (`method` `'distance'`). `neighbours{i}` lists the neighbours of antenna *i*. Neighbourhoods may overlap, and *j* being a neighbour of *i* does not make *i* a neighbour of *j*.

By default only antennas that share a measured channel with antenna *i* are considered, so that the reference channels formed from the neighbourhood (see [referenceChannels](referenceChannels.md)) exist in the data.

## Examples

### Two nearest antennas on the Galway array

```matlab
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
neighbours = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
neighbours{1}       % [2 10]: the adjacent antennas in ring 1
neighbours{21}      % [22 24]
```

### All antennas within a distance

```matlab
neighbours = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.09);
neighbours{1}       % [2 3 9 10]: antennas one and two places away in ring 1
```

### Without the measured-channel restriction

```matlab
neighbours = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2, 'MeasuredOnly', false);
neighbours{1}       % [11 20]: in the ring above, 34 mm away
```

The Galway data contain no channel between rings, so channels 1-11 and 1-20 could not serve as references.

## Input Arguments

### `locations` — antenna coordinates

N x 3 numeric array

x, y and z coordinates of the N antennas, for example MERIT's `antenna_locations` in metres. An N x 2 array is accepted and treated as z = 0. `Distance` has the same units.

### `channelPairs` — Tx and Rx antenna of each channel

C x 2 array of antenna numbers

MERIT's `channel_names`: row c gives the transmitting and receiving antenna of channel c. It decides which antennas are candidate neighbours.

### `method` — neighbourhood rule

`'nearest'` | `'distance'`

`'nearest'` takes the `K` candidates closest to the antenna; `'distance'` takes all candidates within `Distance`.

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `K` | nonnegative integer | required for `'nearest'` | Number of neighbours. If fewer candidates exist, all are taken. |
| `Distance` | nonnegative scalar | required for `'distance'` | Largest distance to a neighbour, in the units of `locations`. |
| `Antennas` | vector of antenna numbers | all antennas | Antennas whose neighbourhoods are computed; the others receive an empty neighbourhood. |
| `MeasuredOnly` | `true`, `false` | `true` | Consider only candidates with a measured channel (see Algorithms); `false` considers all antennas. |

## Output Arguments

### `neighbours` — neighbourhood of each antenna

N x 1 cell array

Element *i* lists the neighbours of antenna *i* in ascending antenna number; an antenna is never its own neighbour.

## Algorithms

- **Candidates.** With `MeasuredOnly`, antenna *m* is a candidate neighbour of antenna *i* when a channel between them is measured in either direction (*i*-*m* or *m*-*i*). For monostatic channels (*m*-*m*), the candidates are the antennas that have their own measured channel.
- **Nearest.** Candidates are ordered by Euclidean distance; at equal distance the lower antenna number comes first. On a regular ring, the two antennas on either side are exactly equally distant.

## See Also

[referenceChannels](referenceChannels.md) | [neighbourhoodEditor](neighbourhoodEditor.md) | [Antenna Neighbourhoods and Reference Channels](../examples/neighbourhoods.md)
