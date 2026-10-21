# merit.process.shape

Multiply frequency-domain signals by a pulse spectrum and convert them to the time domain

Package: `merit.process`

## Syntax

```text
td = merit.process.shape(fd, pulse, frequency_axis, time_axis)
```

## Description

`td = merit.process.shape(fd, pulse, frequency_axis, time_axis)` gives the time-domain response of each channel to a transmitted pulse whose spectrum, sampled at `frequency_axis`, is `pulse`. It is equivalent to `merit.process.fd2td(fd .* pulse(:), frequency_axis, time_axis)`.

## Examples

### Response to a Gaussian-modulated pulse

```matlab
frequencies = dlmread('data/frequencies.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');

pulse = exp(-((frequencies - 3e9) / 1e9).^2);
time_axis = 0:1e-11:4e-9;
td = merit.process.shape(signals, pulse, frequencies, time_axis);
size(td)
```

The pulse spectrum is centred on 3 GHz and tapers the band edges, which reduces the ringing of the time-domain signals.

## Input Arguments

### `fd` — frequency-domain signals

N_f x C x ... array

### `pulse` — pulse spectrum

vector of length N_f

The complex amplitude of the pulse at each frequency.

### `frequency_axis` — frequency of each sample

increasing vector of length N_f, in hertz, with a constant step

### `time_axis` — times at which to evaluate the signals

increasing vector, in seconds, with a constant step

## Output Arguments

### `td` — shaped time-domain signals

N_t x C x ... real array

## See Also

[merit.process.fd2td](fd2td.md)
