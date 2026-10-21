# merit.utility.under

Apply a function between a transformation of its inputs and a transformation of its output

Package: `merit.utility`

## Syntax

```text
result = merit.utility.under(op, f, f_inv, A1, ..., An)
```

## Description

`result = merit.utility.under(op, f, f_inv, A1, ..., An)` computes `f_inv(op(f(A1), ..., f(An)))`: each input is transformed with `f`, the operation `op` is applied, and its result is transformed with `f_inv`, usually the inverse of `f`.

## Examples

### Euclidean norm as a sum under squaring

```matlab
merit.utility.under(@sum, @(a) a.^2, @sqrt, [3 4])
```

The result is 5.

## Input Arguments

### `op` — operation

function handle taking n inputs

### `f` — transformation of each input

function handle

### `f_inv` — transformation of the result

function handle

### `A1, ..., An` — inputs

## Output Arguments

### `result` — transformed result

## See Also

[merit.utility.reshape2d](reshape2d.md)
