# merit.process.fd2td

Convert frequency-domain signals to the time domain with the inverse chirp-z transform

Package: `merit.process`

## Syntax

```text
td = merit.process.fd2td(signals, frequency_axis, time_axis)
```

## Description

`td = merit.process.fd2td(signals, frequency_axis, time_axis)` evaluates the real time-domain signals that correspond to the frequency samples in `signals` at the times in `time_axis`. The frequencies need not start at zero and the times can be chosen freely, which a plain inverse FFT does not allow.

## Examples

### Convert a rotation-subtracted scan

```matlab
frequencies = dlmread('example_data/frequencies.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');

time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
size(td)
figure;
plot(time_axis*1e9, td(:, 1));
xlabel('Time (ns)');
```

`td` is a real 401 x 96 array.

### Only non-negative times are returned

```matlab
td2 = merit.process.fd2td(signals, frequencies, -1e-9:1e-11:2e-9);
size(td2, 1)
```

Of the 301 times, only the 200 that are greater than or equal to zero in floating point are returned.

## Input Arguments

### `signals` — frequency-domain signals

N_f x C x ... array

### `frequency_axis` — frequency of each sample

increasing vector of length N_f, in hertz, with a constant step

### `time_axis` — times at which to evaluate the signals

increasing vector, in seconds, with a constant step

## Output Arguments

### `td` — time-domain signals

N_t x C x ... real array

N_t is the number of non-negative values in `time_axis`.

## Algorithms

The function evaluates

```text
td(t) = real( sum over k of S(f_k) exp(j2π f_k t) ) / N_t
```

for each non-negative t in `time_axis`. The sum is computed with the chirp-z transform (`czt`), applied to the conjugate of the signals and conjugated again, and the phase of the lowest frequency is applied afterwards.

## Tips

- The scaling by 1/N_t depends on the number of time samples, not on the number of frequencies. Two conversions with different time axes therefore have different amplitudes.
- The function needs the Signal Processing Toolbox for `czt`.

## See Also

[merit.process.td2fd](td2fd.md) | [merit.process.shape](shape.md) | [merit.beamform](../beamform.md)
