# Getting Started with MERIT

This page installs MERIT 1.0.1 and follows the imaging pipeline of its script `getting_started.m`: loading measured scans, removing the artefact by rotation subtraction, defining the imaging domain, calculating delays, beamforming, and displaying the image as a slice and in three dimensions. It then evaluates the image with two metrics and repeats the imaging in the time domain.

## Requirements

- MATLAB R2021a or later. The functions use `arguments` blocks and validation functions introduced in R2020b, and the scripts use the `Name=Value` syntax introduced in R2021a. For older releases, use the [2019 snapshot](../merit-2019/getting-started.md).
- The Signal Processing Toolbox is needed by [merit.process.resample](process/resample.md) and by the chirp-z transform in [merit.process.fd2td](process/fd2td.md) and [merit.process.td2fd](process/td2fd.md).
- The Statistics and Machine Learning Toolbox is needed by [merit.display.as_3D_scan](display/as_3D_scan.md).
- The Parallel Computing Toolbox and a supported GPU are needed only for the `gpu` option of [merit.beamform](beamform.md).

## Installation

In a terminal, in the folder that is to contain MERIT:

```bash
git clone https://github.com/EMFMed/MERIT.git
cd MERIT
git checkout v1.0.1
```

The tag `v1.0.1` is the commit merged into `master`; omit the last line to use the latest `master`. Start MATLAB, change the current folder to `MERIT` and add it to the path:

```matlab
addpath(pwd);
which merit.process.delay
```

`which` should print a path ending in `+merit\+process\delay.m` inside this folder. Add only the MERIT folder itself; MATLAB finds the package folders beginning with `+` through it. Every version of MERIT defines the package `merit`, so only one version may be on the path at a time.

## Example data

The `example_data` folder contains measurements of breast phantoms from the BRIGID dataset, described in B. L. Oliveira et al., "Microwave breast imaging: experimental tumour phantoms for the evaluation of new breast cancer diagnosis systems", Biomedical Physics & Engineering Express 4, 025036, 2018.

| File | Content |
|---|---|
| `frequencies.csv` | 76 frequencies from 1.5 GHz to 4.5 GHz in steps of 40 MHz, in hertz. |
| `antenna_locations.csv` | The coordinates of the 24 antennas in metres, one antenna per row. |
| `channel_names.csv` | The 96 measured channels, one per row: transmitting antenna, receiving antenna. |
| `<phantom>_P<n>_p000.csv` | A scan of one of the phantoms B0, B10E, B15E, B20E and B30E with the tumour in position n, from 0 to 22. |
| `<phantom>_P<n>_p036.csv` | The same phantom after a rotation of 36 degrees, for artefact removal. |

Each scan is a 76 x 96 array of complex scattering parameters: one row per frequency and one column per channel, in the order of `channel_names.csv`. MERIT uses this layout throughout: the first dimension of a signal array holds the samples, in frequency or in time, and the second holds the channels. In B0_P3, the homogeneous phantom B0 contains a tumour of 11 mm diameter at (15, 0, 35) mm.

## Load the scans and remove the artefact

```matlab
frequencies = dlmread('example_data/frequencies.csv');
antenna_locations = dlmread('example_data/antenna_locations.csv');
channel_names = dlmread('example_data/channel_names.csv');
[scan1, scan2] = load_example_scan("B0", 3);

signals = scan1 - scan2;
```

`load_example_scan(phantom, position)`, in the MERIT folder, reads the scan and the rotated scan of a phantom and tumour position. The rotation moves the tumour relative to the antennas while the reflections from the skin and the antennas themselves change little, so the difference of the two scans retains mainly the tumour response. The script `merit.example_scripts.plot_mag_and_phase` plots the magnitude and phase of the first channel before and after the subtraction.

## Define the imaging domain

```matlab
[points, axes_] = merit.domain.hemisphere(7e-2, resolution=2.5e-3);
```

`points` lists the grid points inside a hemisphere of 7 cm radius with a spacing of 2.5 mm, one point per row, and `axes_` holds the three grid axes. See [merit.domain.hemisphere](domain/hemisphere.md).

## Calculate the delays

```matlab
delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
```

`delays` is a function: `delays(points)` returns, for every channel and every point, the time taken by a wave to travel from the transmitting antenna to the point and back to the receiving antenna in a medium of relative permittivity 8. The permittivity must be given. See [merit.get_delay](get_delay.md).

## Form the image

```matlab
img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DAS));
```

[merit.beamform](beamform.md) delays every channel by its delay to each point and passes the delayed signals to the beamformer, here delay-and-sum ([merit.beamformer.DAS](beamformer/DAS.md)). For frequency-domain signals the result is complex, so its magnitude is taken. `img` holds one value per point.

## Display a slice

```matlab
im_slice = merit.domain.get_slice(img, points, axes_, z=35e-3);
figure;
imagesc(axes_{1}*1e3, axes_{2}*1e3, im_slice.');
axis xy equal tight;
xlabel('x (mm)');
ylabel('y (mm)');
title('z = 35 mm');
colorbar;
```

[merit.domain.get_slice](domain/get_slice.md) returns the plane z = 35 mm as a grid whose rows follow the x axis and whose columns follow the y axis. `imagesc` draws rows vertically, so the slice is transposed to show x horizontally; `getting_started.m` passes the slice without transposing it, which exchanges the x and y directions in the figure. Points outside the hemisphere are `NaN`.

## Display the image in three dimensions

```matlab
grid_ = merit.domain.img2grid(img, points, axes_{:});
merit.display.as_3D_scan(grid_);
```

[merit.domain.img2grid](domain/img2grid.md) places the image values on the three-dimensional grid, and [merit.display.as_3D_scan](display/as_3D_scan.md) draws it as semi-transparent planes whose opacity increases with the value. The axes of this figure show grid indices.

## Locate the maximum and evaluate the image

```matlab
[~, peak] = max(img);
location = points(peak, :)
[width_x, width_y, width_z] = merit.metric.FWHM(img, points, axes_{:})
scr = merit.metric.SCR(img, points, axes_{:})
```

[merit.metric.FWHM](metric/FWHM.md) gives the width of the main response along each axis in metres, and [merit.metric.SCR](metric/SCR.md) the ratio in decibels of the maximum to the largest value outside the main response. Pass the axes to both metrics; without them, the widths are counted in grid steps.

## Image in the time domain

The same pipeline works with time-domain signals. [merit.process.fd2td](process/fd2td.md) converts the scans, and a window from [merit.domain.windows.rectangular](domain/windows/rectangular.md) restricts the beamformer to the first samples after delaying:

```matlab
time_axis = 0:1e-11:4e-9;
td = merit.process.fd2td(signals, frequencies, time_axis);
img_td = merit.beamform(td, time_axis, points, delays, merit.beamformer.DAS, ...
    window=merit.domain.windows.rectangular(100));
```

The window is needed in the time domain. [merit.process.delay](process/delay.md) shifts each time signal by whole samples and fills the vacated samples with `NaN`; without a window, every image value would be `NaN`. For the Galway array at a permittivity of 8, the largest delay is about 2.6 ns, or 260 samples, so the first 100 of the 401 samples are always valid.

## Next steps

- [merit.beamform](beamform.md) describes the memory limit and the GPU option.
- The [function index](README.md) lists all functions and their names in earlier versions.
- [merit.test.run_all](test/run_all.md) runs the unit tests.
