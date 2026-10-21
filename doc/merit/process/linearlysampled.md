# merit.process.linearlysampled

Test whether an axis has a constant step

Package: `merit.process`

## Syntax

```text
tf = merit.process.linearlysampled(axis_)
```

## Description

`tf = merit.process.linearlysampled(axis_)` returns true if the differences between consecutive elements of `axis_` are constant to within rounding error.

## Examples

### Test three axes

```matlab
merit.process.linearlysampled(0:0.1:1)
merit.process.linearlysampled([0 1 3])
merit.process.linearlysampled(dlmread('example_data/frequencies.csv'))
```

The results are true, false and true.

## Input Arguments

### `axis_` — axis to test

numeric vector

## Output Arguments

### `tf` — whether the axis is linearly sampled

logical scalar

## Algorithms

The axis is accepted if every second difference, `diff(axis_, 2)`, is at most ten times the largest floating-point spacing `eps` of the axis values.

## Tips

- The test is one-sided: large negative second differences are accepted, so an axis whose step decreases, such as `[0 2 3]`, is reported as linearly sampled.

## See Also

[merit.process.fd2td](fd2td.md) | [merit.process.td2fd](td2fd.md) | [merit.process.delay](delay.md)
