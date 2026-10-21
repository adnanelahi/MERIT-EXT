# Extending MERIT and MERIT-EXT

New methods, such as a beamformer, a delay model or an artefact-removal method, can be developed alongside MERIT and MERIT-EXT and used with them unchanged, because MERIT passes its building blocks to one another as function handles. This page describes where to put such functions, the interfaces they must follow, and how a finished function is proposed for inclusion in MERIT-EXT or in MERIT.

## Where to put the code

Develop in your own project folder, next to MERIT and MERIT-EXT, with the folder layout and the `setupPaths` script described in [Getting Started](getting-started.md#folder-layout), and leave the MERIT and MERIT-EXT folders unchanged.

Write a new function in the package where it is meant to end up, so that it has its final name from the start and needs no renaming when it is proposed for inclusion: an artefact-removal method in `artefact` of MERIT-EXT, a beamformer in `merit.beamformer` of MERIT, and so on. MATLAB merges packages of the same name that lie in different folders on the path, so the package folder is created inside your project:

```text
my-project/
  setupPaths.m
  myAnalysis.m              % your scripts
  +artefact/
    subtractSubspace.m      % called as artefact.subtractSubspace
  +merit/
    +beamformer/
      CFDAS.m               % called as merit.beamformer.CFDAS
```

With the project, MERIT and MERIT-EXT on the path, `artefact.subtractSubspace` is called like the functions of MERIT-EXT, and `merit.beamformer.CFDAS` like those of MERIT. When the function is proposed for inclusion, the file is copied unchanged into a branch of a fork of the target repository (see [Proposing a function for inclusion](#proposing-a-function-for-inclusion)).

Give the function a name that the package does not already use: a file with the name of an existing function would shadow it or be shadowed by it, depending on the order of the folders on the path. `which -all artefact.subtractSubspace` lists every file that defines a name.

## Data layout

Every signal array has the samples in the first dimension, in frequency or in time, and the channels in the second, in the order of the rows of `channel_names`. Complex arrays are treated as frequency-domain signals and real arrays as time-domain signals. Lengths are in metres, times in seconds and frequencies in hertz.

## A beamformer

[merit.beamform](merit-2019/beamform.md) takes the beamformer as a function handle. The function receives the delayed signals, an array of samples x channels x points, and returns one value per point as a points x 1 column. A delay-and-sum beamformer that takes the magnitude before squaring can be written in one line:

```matlab
myDAS = @(x) shiftdim(sum(abs(sum(x, 2)).^2, 1), 2);
img = merit.beamform(signals, timeAxis, points, delays, myDAS, 'window', window);
```

`sum(x, 2)` sums over the channels and `sum(..., 1)` over the samples; `shiftdim(..., 2)` turns the 1 x 1 x points result into a column. Longer beamformers belong in a file, following MERIT's pattern of a function that returns the handle, here delay-and-sum weighted by a coherence factor between 0 and 1:

```matlab
function image_ = coherenceDAS()
    image_ = @process;
end

function values = process(x)
    C = size(x, 2);
    coherent = sum(sum(x, 2).^2, 1);            % energy of the channel sum
    total = sum(sum(x.^2, 1), 2);               % total energy of the channels
    values = shiftdim(coherent .* coherent ./ (C * total), 2);
end
```

`merit.beamform(signals, timeAxis, points, delays, coherenceDAS(), 'window', window)` then uses it. `merit.beamform` calls the beamformer on blocks of points to stay within its memory limit, so the function must work for any number of points in the third dimension.

## A delay function

The delay function receives a P x 3 block of points in metres and returns the delay of every channel to each point as a 1 x C x P array in seconds, negative so that the signals are advanced. A function from [merit.beamform.get_delays](merit-2019/beamform/get_delays.md) can be wrapped, for example to add a fixed delay of 0.19 ns at each antenna:

```matlab
freeDelays = merit.beamform.get_delays(pairs, locations, 'relative_permittivity', 8);
myDelays = @(p) freeDelays(p) - 2 * 0.19e-9;
```

### Writing a new delay function

`get_delays` (`merit.get_delay` in MERIT 1.0.1) describes one format: a fixed array of antennas, channels given as pairs of antenna numbers, straight propagation paths and one homogeneous medium. Data in other formats need a delay function of their own, for example:

- scans in which the antennas move between measurements, so that each channel has its own transmitter and receiver positions instead of antenna numbers;
- monostatic scans, in which each channel is one antenna position, possibly with a delay inside the antenna;
- a breast surrounded by a coupling medium of different permittivity, in which each path crosses two media;
- a permittivity or speed that varies between points, which MERIT's own TODO lists as a goal.

Such a function follows the pattern of `get_delays`: it takes the description of the measurement and returns a function handle, which `merit.beamform` calls with blocks of points. The handle must return a 1 x C x P array of delays in seconds, negative for advancing the signals, for any number of points P. The example below takes the transmitter and receiver position of each channel directly:

```matlab
function calculate_time = channel_position_delays(tx, rx, relative_permittivity)
% CHANNEL_POSITION_DELAYS Delays from the positions of each channel's antennas.
%   calculate_time = channel_position_delays(TX, RX, ER) returns a function
%   for merit.beamform. TX and RX are C x 3 arrays giving, for each of the C
%   channels, the position in metres of its transmitting and receiving
%   antenna, so that antennas may move between channels. ER is the relative
%   permittivity of the homogeneous medium.
%
%   t = calculate_time(points) takes a P x 3 array of points in metres and
%   returns the 1 x C x P array of round-trip times in seconds, negative so
%   that merit.process.delay advances the signals.
c0 = 299792458;
speed = c0 / sqrt(relative_permittivity);
calculate_time = @(points) -(distance(tx, points) + distance(rx, points)) / speed;
end

function d = distance(positions, points)
% 1 x C x P distances between the C positions and the P points.
d = sqrt(sum((permute(positions, [2 1 3]) - permute(points, [2 3 1])).^2, 1));
end
```

For a fixed array it gives the same delays as `get_delays`:

```matlab
delays = channel_position_delays(locations(pairs(:, 1), :), locations(pairs(:, 2), :), 8);
```

A new delay function for other formats is a good candidate for inclusion in MERIT, because `merit.beamform` and every beamformer can use it without change.

## A window

The `'window'` option of `merit.beamform` takes a function that receives the delayed signals and returns the part to be combined, for example the first L samples, as [merit.beamform.windows.rectangular](merit-2019/beamform/windows/rectangular.md) does. A tapered window, or one that skips the early samples, is written in the same way.

## An artefact-removal function

An artefact-removal function takes the signals of one scan, samples x channels, and returns an array of the same size, as [artefact.subtractAverage](artefact/subtractAverage.md) does. It can then take the place of `subtractAverage` in the [tutorial](tutorials/average-subtraction-pipeline.md) without any other change.

## Tests and evaluation

Write the checks as a `matlab.unittest` test class in the package's test folder in your project, as MERIT and MERIT-EXT do, for example `my-project/+artefact/+test/test_subspace.m`, and run them with `runtests('artefact.test')`, which also runs the tests of MERIT-EXT in the merged package. Test the function on small synthetic arrays whose correct result is known, as well as on measured data. The [tutorial](tutorials/average-subtraction-pipeline.md) provides a complete pipeline for evaluating a method on the Galway phantom data against rotation subtraction, with the distance of the image maximum from the tumour, the full width at half maximum, the signal-to-clutter and signal-to-mean ratios, and the correlation with the rotation-subtracted image.

## Proposing a function for inclusion

A method that works and has been evaluated can be proposed for inclusion in MERIT-EXT or in MERIT (`https://github.com/EMFMed/MERIT`). MERIT's README welcomes contributions of code and documentation.

1. **Choose the target and its place.** Artefact-removal methods and signal displays belong in the packages `artefact` and `signalvis` of MERIT-EXT. Beamformers, metrics, delay models and processing functions belong in MERIT. MERIT 1.0.1, on its `master` branch, groups its functions in the packages `+beamformer`, `+domain`, `+metric`, `+process` and `+display`, names functions in lower case with underscores (`get_delay`, `as_3D_scan`) and validates inputs with `arguments` blocks, which need MATLAB R2021a or later; its [documentation](merit/README.md) lists every function and its name in earlier versions.
2. **Adapt the code** to the conventions of the target: name and package, help text that describes the inputs and outputs, input validation, and no hard-coded paths or version names.
3. **Add tests** in the target's test package: `+merit/+test/+from_list` in MERIT, `+artefact/+test` or `+signalvis/+test` in MERIT-EXT.
4. **Add documentation**: a reference page in the format of the pages in this documentation, with syntax, description, examples, arguments and algorithm, and an entry in the package's `Contents.m` for MERIT-EXT.
5. **Open a pull request.** Fork the target repository on GitHub, clone the fork into a separate folder, create a branch, copy the function with its tests and documentation into the package folders, commit them, and open a pull request against `master` (MERIT) or `main` (MERIT-EXT). While the fork is tested, keep only one copy of the function on the path: remove your project folder from the path or rename its copy. Describe the method with a reference to its publication, the evaluation results, and any limitation found.

MERIT is licensed under Apache 2.0; contributed code is released under the same licence.

## See Also

[Tutorial: From Measured Scans to an Image with Average Subtraction](tutorials/average-subtraction-pipeline.md) | [MERIT 1.0.1 documentation](merit/README.md) | [TODO](../TODO.md)
