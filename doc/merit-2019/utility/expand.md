# merit.utility.expand

Replicate arrays along their singleton dimensions to a common size

Package: `merit.utility`

## Syntax

```text
[A1, ..., An] = merit.utility.expand(B1, ..., Bn)
```

## Description

`[A1, ..., An] = merit.utility.expand(B1, ..., Bn)` replicates each input along its dimensions of size 1 so that all outputs have the same size. In every dimension, the inputs must have either the same size or size 1. The result is the same as the implicit expansion of arithmetic operators in MATLAB R2016b and later, but the arrays are formed explicitly.

## Examples

### Expand a row and a column

```matlab
[a, b] = merit.utility.expand([1 2 3], [4; 5])
```

`a` is `[1 2 3; 1 2 3]` and `b` is `[4 4 4; 5 5 5]`.

## Input Arguments

### `B1, ..., Bn` — arrays to expand

arrays with compatible sizes

## Output Arguments

### `A1, ..., An` — expanded arrays

arrays of the common size

## Tips

- Incompatible sizes cause the error "Dimensions need to be the same or one for all inputs."
- [merit.process.txrx2ind](../process/txrx2ind.md) uses this function to expand the transmitting and receiving antennas.

## See Also

[merit.utility.expand2](expand2.md)
