# merit.process.remap

Rename antennas and reorder the channels accordingly

Package: `merit.process`

## Syntax

```text
[remapped, new_channels] = merit.process.remap(signals, new_antenna_names)
[remapped, new_channels] = merit.process.remap(signals, new_antenna_names, original_channels)
```

## Description

`[remapped, new_channels] = merit.process.remap(signals, new_antenna_names)` renames the antennas of a full set of A² channels (S11, S12, ..., S1A, S21, ..., SAA) and reorders the columns of `signals` so that the channels are again in this order under the new names.

`[remapped, new_channels] = merit.process.remap(signals, new_antenna_names, original_channels)` does the same for any set of channels, listed in `original_channels`.

## Examples

### Renumber three antennas

```matlab
signals = repmat(1:9, 2, 1);
[remapped, new_channels] = merit.process.remap(signals, [3 1 2]);
remapped(1, :)
new_channels'
```

Antenna 1 becomes 3, antenna 2 becomes 1 and antenna 3 becomes 2. The new channel 1-1 is the original channel 2-2, the fifth column, so `remapped(1, :)` is `[5 6 4 8 9 7 2 3 1]`. `new_channels` lists the renamed channels in the original column order: `[3 3; 3 1; 3 2; 1 3; ...]`.

### Exchange two antennas in a reduced channel list

```matlab
[remapped, new_channels] = merit.process.remap(repmat(1:3, 2, 1), [2 1], [1 1; 1 2; 2 2]);
remapped(1, :)
```

The result is `[3 2 1]`: the new channel 1-1 is the original 2-2. The original channel 1-2 becomes 2-1, which is not in the list, so it is stored as 1-2.

## Input Arguments

### `signals` — signals in the original channel order

N x M array

### `new_antenna_names` — new name of each antenna

vector with one element for each antenna

Element k is the new number of the original antenna k. Use `NaN` for an antenna that appears in no channel.

### `original_channels` — original channels

M x 2 array (default: all A² channels in the order S11, S12, ..., SAA)

One channel per row: transmitting antenna, receiving antenna.

## Output Arguments

### `remapped` — reordered signals

N x M array

The columns sorted by the new transmitting antenna and then by the new receiving antenna.

### `new_channels` — renamed channels

M x 2 array

The renamed channels in the original column order, not in the order of `remapped`. `sortrows(new_channels)` gives the channel list that matches `remapped`.

## Algorithms

Each channel is renamed with `new_antenna_names`. If a renamed channel i-j has i > j and the channel j-i does not occur among the renamed channels, it is stored as j-i, so that reciprocal channels measured only once keep the transmitting antenna lower. The columns are then sorted with `sortrows`.

## Tips

- Without `original_channels`, the number of columns must be a perfect square.
- The error identifiers of this function begin with `smartimaging:` rather than `merit:`.

## See Also

[merit.process.txrx2ind](txrx2ind.md)
