# merit.get_delay

Create a function that returns the propagation delay of every channel to given points

Package: `merit`

## Syntax

```text
calculate_time = merit.get_delay(channels, antennas, relative_permittivity=er)
```

## Description

`calculate_time = merit.get_delay(channels, antennas, relative_permittivity=er)` returns a function handle. `calculate_time(points)` gives, for each channel and each point, the time taken by a wave to travel from the transmitting antenna of the channel to the point and from the point to the receiving antenna, in a homogeneous medium of relative permittivity `er`. The times are negative, so that [merit.process.delay](process/delay.md) advances each signal by its travel time.

## Examples

### Delays to two points in the Galway array

```matlab
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');

delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
t = delays([0, 0, 0.03; 0.015, 0, 0.035]);
size(t)
```

`t` is 1 x 96 x 2: one delay for each of the 96 channels and each of the two points.

### Add a constant antenna delay

```matlab
free_space = merit.get_delay(channel_names, antenna_locations, relative_permittivity=1);
delays = @(points) free_space(points) - 2*0.19e-9;
```

The new function adds 0.19 ns at the transmitting and at the receiving antenna, as `merit.example_scripts.create_ummid_render` does for the UM-BMID antennas.

## Input Arguments

### `channels` — transmitting and receiving antenna of each channel

C x 2 array of positive integers

One channel per row: the index of the transmitting antenna in the first column and of the receiving antenna in the second. The indices refer to the rows of `antennas`.

### `antennas` — antenna positions

A x D real array

The coordinates of each antenna in metres, one antenna per row. D is the number of coordinates, 2 or 3, and must equal the number of columns of the points given to `calculate_time`.

## Name-Value Arguments

| Name | Value | Default | Description |
|---|---|---|---|
| `relative_permittivity` | real scalar, at least 1 | none | Relative permittivity of the medium, assumed to be homogeneous and lossless. The argument has no default value and must be given. |

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

- Calling the function without `relative_permittivity` stops with an error, because the code reads the option although no default is declared.
- The delay assumes straight propagation paths in a single medium. Refraction at the skin and the immersion medium is not modelled.
- [merit.beamform](beamform.md) calls `calculate_time` with blocks of points, so a custom delay function must accept any number of rows and return a 1 x C x P array.
- The function was called `merit.beamform.get_delays` before version 1.0.1. Its help text still shows the old name.

## See Also

[merit.beamform](beamform.md) | [merit.process.delay](process/delay.md)
