# merit.utility.reshape2d

Apply a function written for matrices to arrays with more dimensions

Package: `merit.utility`

## Syntax

```text
result = merit.utility.reshape2d(f, A1, ..., An)
```

## Description

`result = merit.utility.reshape2d(f, A1, ..., An)` reshapes each N x C x ... input to a matrix with N rows, calls `f` with these matrices, and reshapes the result back to the trailing dimensions of `A1`. The number of rows of the result may differ from N.

## Examples

### Cumulative sum over the samples of a three-dimensional array

```matlab
result = merit.utility.reshape2d(@(a) cumsum(a), ones(3, 2, 4));
size(result)
result(end)
```

The result is 3 x 2 x 4, and its last element is 3.

## Input Arguments

### `f` — function to apply

function handle

Takes as many matrices as there are arrays and returns one matrix whose number of columns is the product of the trailing dimensions.

### `A1, ..., An` — arrays

arrays with the same sizes in the second and higher dimensions

## Output Arguments

### `result` — result of f

array of size `[size(f(...), 1), size(A1, 2), size(A1, 3), ...]`

## Tips

- Arrays whose trailing dimensions differ cause the error "Input arrays must have the same trailing dimension sizes".

## See Also

[merit.utility.under](under.md)
