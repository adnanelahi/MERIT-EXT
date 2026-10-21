# merit.process.txrx2ind

Find the indices of channels from their transmitting and receiving antennas

Package: `merit.process`

## Syntax

```text
inds = merit.process.txrx2ind(channels, tx, rx)
inds = merit.process.txrx2ind(channels, antennas)
```

## Description

`inds = merit.process.txrx2ind(channels, tx, rx)` returns the rows of `channels` whose transmitting antenna is `tx` and whose receiving antenna is `rx`. `tx` and `rx` are expanded to a common size, and `inds` has that size.

`inds = merit.process.txrx2ind(channels, antennas)` returns the monostatic channels of the given antennas, the channels k-k.

## Examples

### Columns of given channels in a Galway scan

```matlab
channel_names = dlmread('data/channel_names.csv');
merit.process.txrx2ind(channel_names, 1, 2)
merit.process.txrx2ind(channel_names, [1 2], [2 3])
merit.process.txrx2ind(channel_names, 2, [3 4])
```

The results are `1`, `[1 2]` and `[2 11]`: channel 2-4 is the eleventh column.

### Monostatic channels

```matlab
merit.process.txrx2ind([1 1; 1 2; 2 2], [1 2])
```

The result is `[1 3]`.

## Input Arguments

### `channels` — channel list

C x 2 array

One channel per row: transmitting antenna, receiving antenna.

### `tx`, `rx` — transmitting and receiving antennas

arrays of compatible sizes

Each dimension of `tx` and `rx` must be equal or 1.

### `antennas` — antennas whose monostatic channels are wanted

array

## Output Arguments

### `inds` — channel indices

array of the expanded size of `tx` and `rx`

## Tips

- Every requested channel must occur in `channels`. A missing channel, for example the monostatic channel 1-1 of the Galway data, causes the error "To RESHAPE the number of elements must not change."
- Reversed channels are not matched: if only 1-2 was measured, asking for 2-1 is an error.

## See Also

[merit.process.remap](remap.md) | [merit.utility.expand](../utility/expand.md)
