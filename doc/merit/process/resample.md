# merit.process.resample

Resample time-domain signals to a new sampling frequency

Package: `merit.process`

## Syntax

```text
[resampled, actual_frequency] = merit.process.resample(signals, from_frequency, to_frequency)
```

## Description

`[resampled, actual_frequency] = merit.process.resample(signals, from_frequency, to_frequency)` resamples each column of `signals` from the sampling frequency `from_frequency` to approximately `to_frequency`. It approximates the ratio of the two frequencies by a fraction P/Q and calls MATLAB's `resample` with P and Q.

## Examples

### Resample from 100 GHz to 250 GHz

```matlab
frequencies = dlmread('example_data/frequencies.csv');
signals = dlmread('example_data/B0_P3_p000.csv') - dlmread('example_data/B0_P3_p036.csv');
td = merit.process.fd2td(signals, frequencies, 0:1e-11:4e-9);

[resampled, actual_frequency] = merit.process.resample(td, 1e11, 2.5e11);
size(resampled)
actual_frequency
```

The 401 samples become 1003 samples, as expected for a ratio of 5/2. `actual_frequency` is 5e11 instead of 2.5e11; see Tips.

## Input Arguments

### `signals` — time-domain signals

N x C array

### `from_frequency` — current sampling frequency in hertz

positive scalar

### `to_frequency` — required sampling frequency in hertz

positive scalar

## Output Arguments

### `resampled` — resampled signals

M x C array, with M ≈ N P / Q

### `actual_frequency` — sampling frequency reported by the function

scalar

## Algorithms

`[P, Q] = rat(to_frequency / from_frequency)` gives the fraction, which approximates the ratio to a relative tolerance of about 1e-6, and `resample(signals, P, Q)` applies an anti-aliasing filter and changes the sampling rate by P/Q.

## Tips

- `actual_frequency` is calculated as P × `from_frequency` instead of P / Q × `from_frequency`, so it is correct only when Q is 1. Calculate the frequency as `from_frequency * size(resampled, 1) / size(signals, 1)`, or from P and Q, instead.
- The function needs the Signal Processing Toolbox.

## See Also

[merit.process.fd2td](fd2td.md)
