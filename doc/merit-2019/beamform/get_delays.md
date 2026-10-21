# merit.beamform.get_delays

Create a function that returns the propagation delay of every channel to given points

Package: `merit.beamform`

## Syntax

```text
calculate_time = merit.beamform.get_delays(channels, antennas)
calculate_time = merit.beamform.get_delays(channels, antennas, 'relative_permittivity', er)
```

## Description

`calculate_time = merit.beamform.get_delays(channels, antennas)` returns a function handle. `calculate_time(points)` gives, for each channel and each point, the time taken by a wave to travel from the transmitting antenna of the channel to the point and from the point to the receiving antenna, in free space. The times are negative, so that [merit.process.delay](../process/delay.md) advances each signal by its travel time.

`calculate_time = merit.beamform.get_delays(channels, antennas, 'relative_permittivity', er)` assumes a homogeneous medium of relative permittivity `er`.

## Examples

### Delays to the centre of the Galway array

```matlab
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');

delays = merit.beamform.get_delays(channel_names, antenna_locations, 'relative_permittivity', 8);
t = delays([0, 0, 0.03; 0.015, 0, 0.035]);
size(t)
t(1, 1, :)
```

`t` is 1 x 96 x 2: one delay for each of the 96 channels and each of the two points. For channel 1-2 the delays are -1.35 ns and -1.15 ns.

### Use the delays with the beamformer

```matlab
frequencies = dlmread('data/frequencies.csv');
signals = dlmread('data/B0_P3_p000.csv') - dlmread('data/B0_P3_p036.csv');
points = merit.domain.hemisphere('radius', 7e-2, 'resolution', 5e-3);
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));
```

## Input Arguments

### `channels` — transmitting and receiving antenna of each channel

C x 2 array of positive integers

One channel per row: the index of the transmitting antenna in the first column and of the receiving antenna in the second. The indices refer to the rows of `antennas`.

### `antennas` — antenna positions

A x D array

The coordinates of each antenna in metres, one antenna per row. D is the number of coordinates, usually 3, and must equal the number of columns of the points given to `calculate_time`.

### `er` — relative permittivity

real scalar, at least 1 (default `1`)

The relative permittivity of the medium, assumed to be homogeneous and lossless.

## Output Arguments

### `calculate_time` — delay function

function handle

`t = calculate_time(points)` takes a P x D array of points in metres and returns a 1 x C x P array of times in seconds.

## Algorithms

For a channel with transmitting antenna at position **a**<sub>t</sub> and receiving antenna at **a**<sub>r</sub>, and a point **p**,

```text
t = -(|a_t - p| + |a_r - p|) / v,    v = c0 / sqrt(er)
```

where c0 = 299792458 m/s.

## Tips

- The delay assumes straight propagation paths in a single medium. Refraction at the skin and the immersion medium is not modelled.
- [merit.beamform](../beamform.md) calls `calculate_time` with blocks of points, so the function must accept any number of rows.
- A custom delay function can be passed to [merit.beamform](../beamform.md) in place of `calculate_time`, provided it returns a 1 x C x P array. For example, `@(p) calculate_time(p) - 2*0.19e-9` adds a constant delay of 0.19 ns at each antenna.

## See Also

[merit.beamform](../beamform.md) | [merit.process.delay](../process/delay.md)
