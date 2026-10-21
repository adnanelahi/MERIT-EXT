# merit.utility.expand2

Replicate arrays to a common size in every dimension except the first

Package: `merit.utility`

## Syntax

```text
[A1, ..., An] = merit.utility.expand2(B1, ..., Bn)
```

## Description

`[A1, ..., An] = merit.utility.expand2(B1, ..., Bn)` works as [merit.utility.expand](expand.md) in the second and higher dimensions and leaves the first dimension unchanged. The inputs may therefore have different numbers of rows. [merit.process.delay](../process/delay.md) uses it to replicate N x C signals and 1 x C x P delays to N x C x P and 1 x C x P.

## Examples

### Expand signals and delays

```matlab
[s, d] = merit.utility.expand2(zeros(4, 3), rand(1, 3, 5));
size(s)
size(d)
```

The sizes are 4 x 3 x 5 and 1 x 3 x 5.

## Input Arguments

### `B1, ..., Bn` — arrays to expand

arrays whose sizes in the second and higher dimensions are equal or 1

## Output Arguments

### `A1, ..., An` — expanded arrays

arrays with a common size in the second and higher dimensions

## Tips

- Incompatible sizes cause the error "Dimensions need to be the same or one for all inputs."

## See Also

[merit.utility.expand](expand.md) | [merit.process.delay](../process/delay.md)
