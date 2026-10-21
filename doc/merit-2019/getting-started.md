# Getting Started with MERIT (2019 snapshot)

This page installs the MERIT snapshot of 4 July 2019 and follows the imaging pipeline of its script `getting_started.m`: loading measured scans, removing the artefact by rotation subtraction, defining the imaging domain, calculating delays, beamforming and displaying the image. It then evaluates the image with two metrics and repeats the imaging in the time domain.

## Requirements

- MATLAB R2016b or later. The snapshot was tested on R2018a.
- The Signal Processing Toolbox is needed by [merit.process.resample](process/resample.md) and by the chirp-z transform in [merit.process.fd2td](process/fd2td.md) and [merit.process.td2fd](process/td2fd.md). The other functions use base MATLAB only.
- The Parallel Computing Toolbox and a supported GPU are needed only for the `'gpu'` option of [merit.beamform](beamform.md).

## Installation

In a terminal, in the folder that is to contain MERIT:

```bash
git clone https://github.com/EMFMed/MERIT.git MERIT-2019
cd MERIT-2019
git checkout -b snapshot-2019-07-04 03ea4972205d6f68f8a666172c6f6b14ca08fa31
```

Start MATLAB, change the current folder to `MERIT-2019` and add it to the path:

```matlab
addpath(pwd);
which merit.process.delay
```

`which` should print a path ending in `+merit\+process\delay.m` inside this folder. Add only the MERIT folder itself; MATLAB finds the package folders beginning with `+` through it. Every version of MERIT defines the package `merit`, so only one version may be on the path at a time.

## Example data

The `data` folder contains measurements of breast phantoms from the BRIGID dataset, described in B. L. Oliveira et al., "Microwave breast imaging: experimental tumour phantoms for the evaluation of new breast cancer diagnosis systems", Biomedical Physics & Engineering Express 4, 025036, 2018.

| File | Content |
|---|---|
| `frequencies.csv` | 76 frequencies from 1.5 GHz to 4.5 GHz in steps of 40 MHz, in hertz. |
| `antenna_locations.csv` | The coordinates of the 24 antennas in metres, one antenna per row. |
| `channel_names.csv` | The 96 measured channels, one per row: transmitting antenna, receiving antenna. |
| `B0_P3_p000.csv`, `B0_P5_p000.csv` | Scans of the homogeneous phantom B0 with a tumour of 11 mm diameter at (15, 0, 35) mm and of 20 mm diameter at (15, 0, 30) mm. |
| `B0_P3_p036.csv`, `B0_P5_p036.csv` | The same phantoms after a rotation of 36 degrees, for artefact removal. |
| `B10E_*.csv` | The corresponding scans of the phantom B10E. |

Each scan is a 76 x 96 array of complex scattering parameters: one row per frequency and one column per channel, in the order of `channel_names.csv`. MERIT uses this layout throughout: the first dimension of a signal array holds the samples, in frequency or in time, and the second holds the channels.

## Load the scans and remove the artefact

```matlab
frequencies = dlmread('data/frequencies.csv');
antenna_locations = dlmread('data/antenna_locations.csv');
channel_names = dlmread('data/channel_names.csv');
scan1 = dlmread('data/B0_P3_p000.csv');
scan2 = dlmread('data/B0_P3_p036.csv');

signals = scan1 - scan2;
```

The rotation moves the tumour relative to the antennas while the reflections from the skin and the antennas themselves change little, so the difference of the two scans retains mainly the tumour response.

To compare the original, rotated and subtracted signals of the first channel:

```matlab
magnitude = mag2db(abs([scan1(:, 1), scan2(:, 1), signals(:, 1)]));
figure;
plot(frequencies/1e9, magnitude);
xlabel('Frequency (GHz)');
ylabel('Magnitude (dB)');
legend('Original scan', 'Rotated scan', 'Rotation-subtracted');
title(sprintf('Channel %d-%d', channel_names(1, :)));
```

## Define the imaging domain

```matlab
[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
```

`points` is a 47185 x 3 list of the grid points inside a hemisphere of 7 cm radius with a spacing of 2.5 mm, and `axes_` holds the three grid axes. See [merit.domain.hemisphere](domain/hemisphere.md).

## Calculate the delays

```matlab
delays = merit.beamform.get_delays(channel_names, antenna_locations, ...
    'relative_permittivity', 8);
```

`delays` is a function: `delays(points)` returns, for every channel and every point, the time taken by a wave to travel from the transmitting antenna to the point and back to the receiving antenna in a medium of relative permittivity 8. See [merit.beamform.get_delays](beamform/get_delays.md).

## Form the image

```matlab
img = abs(merit.beamform(signals, frequencies, points, delays, ...
    merit.beamformers.DAS));
```

[merit.beamform](beamform.md) delays every channel by its delay to each point and passes the delayed signals to the beamformer, here delay-and-sum ([merit.beamformers.DAS](beamformers/DAS.md)). For frequency-domain signals the result is complex, so its magnitude is taken. `img` holds one value per point. On a current desktop computer this step takes a few seconds.

## Display a slice

```matlab
im_slice = merit.visualize.get_slice(img, points, axes_, 'z', 35e-3);
figure;
imagesc(axes_{1}*1e3, axes_{2}*1e3, im_slice.');
axis xy equal tight;
xlabel('x (mm)');
ylabel('y (mm)');
title('z = 35 mm');
colorbar;
```

[merit.visualize.get_slice](visualize/get_slice.md) returns the plane z = 35 mm as a grid whose rows follow the x axis and whose columns follow the y axis. `imagesc` draws rows vertically, so the slice is transposed to show x horizontally; `getting_started.m` passes the slice without transposing it, which exchanges the x and y directions in the figure. Points outside the hemisphere are `NaN`.

## Locate the maximum and evaluate the image

```matlab
[~, peak] = max(img);
location = points(peak, :)
[width_x, width_y, width_z] = merit.metrics.FWHM(img, points, axes_{:})
scr = merit.metrics.SCR(img, points, axes_{:})
```

The maximum lies at (15, 2.5, 27.5) mm, close to the tumour at (15, 0, 35) mm. [merit.metrics.FWHM](metrics/FWHM.md) gives the width of the main response along each axis in metres, and [merit.metrics.SCR](metrics/SCR.md) the ratio in decibels of the maximum to the largest value outside the main response. Pass the axes to both metrics; without them, the widths are counted in grid steps.

## Image in the time domain

The same pipeline works with time-domain signals. [merit.process.fd2td](process/fd2td.md) converts the scans, and a window from [merit.beamform.windows.rectangular](beamform/windows/rectangular.md) restricts the beamformer to the first samples after delaying:

```matlab
time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
img_td = merit.beamform(td, time_axis, points, delays, merit.beamformers.DAS, ...
    'window', merit.beamform.windows.rectangular(100));
[~, peak] = max(img_td);
points(peak, :)
```

The window is needed in the time domain. [merit.process.delay](process/delay.md) shifts each time signal by whole samples and fills the vacated samples with `NaN`; without a window, every image value would be `NaN`. Here the largest delay is 2.6 ns, or 260 samples, so the first 100 of the 401 samples are always valid. The maximum lies at (15, 2.5, 25) mm.

## Next steps

- [merit.beamform](beamform.md) describes the memory limit and the GPU option.
- The [function index](README.md) lists all functions of the snapshot.
- The scripts `merit.examples.image_B0` and `merit.examples.image_B10E` image two tumour positions in each of two phantoms.
