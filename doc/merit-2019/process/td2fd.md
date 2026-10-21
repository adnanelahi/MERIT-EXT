# merit.process.td2fd

Convert time-domain signals to the frequency domain with the chirp-z transform

Package: `merit.process`

## Syntax

```text
fd = merit.process.td2fd(signals, time_axis, frequency_axis)
```

## Description

`fd = merit.process.td2fd(signals, time_axis, frequency_axis)` evaluates the spectrum of the real time-domain signals at the frequencies in `frequency_axis`.

## Examples

### Convert to the time domain and back

```matlab
frequencies = dlmread('data/frequencies.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
fd = merit.process.td2fd(td, time_axis, frequencies);
size(fd)
```

`fd` is a complex 76 x 96 array at the original frequencies. Its values differ from `signals` by the scaling and truncation of the two transforms.

## Input Arguments

### `signals` — time-domain signals

N_t x C x ... real array

### `time_axis` — time of each sample

increasing vector of length N_t, in seconds, with a constant step

### `frequency_axis` — frequencies at which to evaluate the spectrum

increasing vector, in hertz, with a constant step

## Output Arguments

### `fd` — frequency-domain signals

N_f x C x ... complex array

## Algorithms

The function evaluates the sum over the time samples of s(t_n) exp(-j2π f (t_n - t_1)) with the chirp-z transform (`czt`).

## Tips

- The phase refers to the first time sample, not to time zero, so a time axis that does not start at zero gives a linear phase offset.
- The function needs the Signal Processing Toolbox for `czt`.

## See Also

[merit.process.fd2td](fd2td.md)
