# merit.domain.circumference

Points spaced evenly around a circle

Package: `merit.domain`

## Syntax

```text
points = merit.domain.circumference(radius, number_of_points, starting_angle)
```

## Description

`points = merit.domain.circumference(radius, number_of_points, starting_angle)` returns `number_of_points` points spaced evenly around a circle of radius `radius` centred on the origin, beginning at the angle `starting_angle`. It is used to describe circular antenna arrays, such as the monostatic scanner of the UM-BMID dataset.

## Examples

### Antenna positions of a monostatic circular scan

```matlab
antenna_locations = merit.domain.circumference(0.21 + 2.4e-2, 72, deg2rad(-130));
delays = merit.get_delay([1:72; 1:72]', antenna_locations, relative_permittivity=1.0932);
figure;
plot(antenna_locations(:, 1), antenna_locations(:, 2), 'o');
axis equal;
```

The radius of 21 cm and the 72 positions are chosen for illustration; `merit.example_scripts.create_ummid_render` reads the radius of each UM-BMID scan from its metadata, adds 2.4 cm for the phase centre of the antenna and starts at -130 degrees. The channel list `[1:72; 1:72]'` describes the 72 monostatic channels, and the delays can be used with a two-dimensional domain from [merit.domain.hemisphere](hemisphere.md) with `no_z=true`.

## Input Arguments

### `radius` — radius of the circle in metres

non-negative scalar

### `number_of_points` — number of points

non-negative scalar

### `starting_angle` — angle of the first point in radians

scalar

Measured from the positive x axis towards the positive y axis. The argument has no default value.

## Output Arguments

### `points` — point coordinates

N x 2 array

The x and y coordinates in metres, in order of increasing angle.

## Algorithms

The angles are `linspace(0, 2*pi*(1 - 1/N), N) + starting_angle`, where N is `number_of_points`, and the coordinates are `radius*[cos(angles); sin(angles)]'`.

## Tips

- The points have two coordinates. Append a column of heights to place them in three dimensions.

## See Also

[merit.domain.hemisphere](hemisphere.md) | [merit.get_delay](../get_delay.md)
