# TODO

Methods that would extend MERIT-Extensions and MERIT. [Extending MERIT and MERIT-Extensions](doc/extending.md) describes where new functions are written and how they are proposed for inclusion.

## Beamformers to implement

The three beamformers below are to be implemented for MERIT 1.0.1, in the package `+merit/+beamformer`, following the conventions described in [Extending MERIT and MERIT-Extensions](doc/extending.md). Each skeleton gives the function signature, its arguments and the help text that `help` displays; the body is left to the implementer. A beamformer of MERIT is a function that returns a handle, and [merit.beamform](doc/merit/beamform.md) calls the handle with the delayed signals of a block of points, an N x C x P array, and expects one value per point.

### Delay-and-sum weighted by the coherence factor (CF-DAS)

M. Klemm, J. A. Leendertz, D. Gibbins, I. J. Craddock, A. Preece and R. Benjamin, "Microwave radar-based breast cancer detection: imaging in inhomogeneous breast phantoms", IEEE Antennas and Wireless Propagation Letters 8, 1349–1352, 2009, [doi:10.1109/LAWP.2009.2036748](https://doi.org/10.1109/LAWP.2009.2036748).

MERIT's `merit.beamformer.CDAS` multiplies the delay-and-sum value by a coherence factor that is not divided by the number of channels and that squares complex values without taking their magnitude ([documented here](doc/merit/beamformer/CDAS.md)). The function below is to implement the coherence factor as defined in the paper, between 0 and 1, for time-domain and frequency-domain signals.

```matlab
function image_ = CFDAS(options)
% CFDAS Delay-and-sum beamformer weighted by the coherence factor.
%   image_ = merit.beamformer.CFDAS() returns a beamformer for merit.beamform
%   that multiplies the delay-and-sum value of each point by the coherence
%   factor of the delayed channels: the energy of their sum divided by the
%   number of channels times the sum of their energies. The factor is 1 when
%   all channels agree and approaches 0 when they cancel, so it suppresses
%   clutter that is not coherent across the channels.
%
%   image_ = merit.beamformer.CFDAS(exponent=p) raises the coherence factor
%   to the power p before weighting (default 1).
%
%   The returned handle takes the delayed signals, an N x C x P array of
%   N samples, C channels and P points (real for time-domain, complex for
%   frequency-domain signals), and returns a P x 1 vector of real,
%   non-negative image values.
%
%   Reference: M. Klemm et al., "Microwave radar-based breast cancer
%   detection: imaging in inhomogeneous breast phantoms", IEEE Antennas and
%   Wireless Propagation Letters 8, 1349-1352, 2009,
%   doi:10.1109/LAWP.2009.2036748.
%
%   Example:
%     img = merit.beamform(signals, frequencies, points, delays, merit.beamformer.CFDAS());
%
%   See also merit.beamform, merit.beamformer.DAS, merit.beamformer.CDAS.
arguments
    options.exponent (1,1) {mustBeNumeric, mustBeNonnegative} = 1
end
image_ = @process;

    function values = process(delayed)
        % delayed: N x C x P delayed signals; values: P x 1 image values.
        error('merit:beamformer:CFDAS:notImplemented', 'CFDAS is not implemented yet.');
    end
end
```

### Delay-multiply-and-sum (DMAS)

H. B. Lim, N. T. T. Nhung, E.-P. Li and N. D. Thang, "Confocal microwave imaging for breast cancer detection: delay-multiply-and-sum image reconstruction algorithm", IEEE Transactions on Biomedical Engineering 55(6), 1697–1704, 2008, [doi:10.1109/TBME.2008.919716](https://doi.org/10.1109/TBME.2008.919716).

MERIT's `merit.beamformer.DMAS` adds some channel pairs twice when there are more than three channels ([documented here](doc/merit/beamformer/DMAS.md)). The function below is to replace it with an implementation that forms every pair of different channels exactly once, as defined in the paper, while keeping the memory use bounded for many channels.

```matlab
function image_ = DMAS(options)
% DMAS Delay-multiply-and-sum beamformer.
%   image_ = merit.beamformer.DMAS() returns a beamformer for merit.beamform
%   that, for each sample and point, multiplies every pair of different
%   delayed channels, sums the products over all C(C-1)/2 pairs, and sums
%   the square of the result over the samples. Responses present in many
%   channels are emphasised more strongly than in delay-and-sum.
%
%   image_ = merit.beamformer.DMAS(pairs_per_block=n) processes the pairs in
%   blocks of n pairs to limit the memory use (default 1000). Every pair is
%   used exactly once, whatever the block size.
%
%   The returned handle takes the delayed signals, an N x C x P array of
%   N samples, C channels and P points, and returns a P x 1 vector of image
%   values; the values are complex for frequency-domain signals, so take
%   abs of the image.
%
%   Reference: H. B. Lim, N. T. T. Nhung, E.-P. Li and N. D. Thang,
%   "Confocal microwave imaging for breast cancer detection: delay-multiply-
%   and-sum image reconstruction algorithm", IEEE Transactions on Biomedical
%   Engineering 55(6), 1697-1704, 2008, doi:10.1109/TBME.2008.919716.
%
%   Example:
%     img = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformer.DMAS()));
%
%   See also merit.beamform, merit.beamformer.DAS, merit.beamformer.CDAS.
arguments
    options.pairs_per_block (1,1) {mustBeInteger, mustBePositive} = 1000
end
image_ = @process;

    function values = process(delayed)
        % delayed: N x C x P delayed signals; values: P x 1 image values.
        error('merit:beamformer:DMAS:notImplemented', 'DMAS is not implemented yet.');
    end
end
```

### Channel-ranked delay-and-sum (CR-DAS)

M. O'Halloran, M. Glavin and E. Jones, "Channel-ranked beamformer for the early detection of breast cancer", Progress In Electromagnetics Research 103, 153–168, 2010, [doi:10.2528/PIER10030902](https://doi.org/10.2528/PIER10030902).

The channel-ranked beamformer gives more weight to the channels with shorter propagation paths to each focal point, because their signals are less likely to be distorted by dielectric heterogeneity. At each focal point, the channels are ranked by their round-trip propagation distance and weighted by their rank before the coherent summation; the image value is the energy of the weighted sum over a time window, as in delay-and-sum. The weighting is to be taken from the reference.

Because the ranks depend on the focal point, the beamformer needs the propagation delay of every channel to every point. MERIT's beamformer handles receive only the delayed signals, so CR-DAS cannot be a beamformer handle like `DAS`; the skeleton below is an imaging function with the arguments of `merit.beamform`, which evaluates the delay function itself to rank the channels. In a homogeneous medium the round-trip distance is proportional to the delay, so the delays give the ranks directly. An alternative is to extend `merit.beamform` so that it passes the delays of each block to the beamformer; the choice between the two is part of the task.

```matlab
function img = channel_ranked_das(signals, axis_, points, delay, options)
% CHANNEL_RANKED_DAS Image with the channel-ranked delay-and-sum beamformer.
%   img = merit.beamformer.channel_ranked_das(signals, axis_, points, delay)
%   forms an image as merit.beamform with merit.beamformer.DAS does, except
%   that each delayed channel is weighted before the channels are summed.
%   At each focal point, the M channels are ranked by their round-trip
%   propagation delay to that point and weighted by their rank, so that
%   channels with shorter propagation paths, which are less likely to be
%   distorted by dielectric heterogeneity, contribute more. The image value
%   is the energy of the weighted sum over the samples.
%
%   img = merit.beamformer.channel_ranked_das(___, window=f, max_memory=m)
%   applies a window to the delayed signals and limits the memory use, as
%   the options of the same names of merit.beamform.
%
%   Inputs:
%     signals  N x M signals of M channels, complex in the frequency domain
%              or real in the time domain.
%     axis_    frequency (Hz) or time (s) of each of the N samples.
%     points   P x 3 imaging points in metres.
%     delay    delay function from merit.get_delay, returning the 1 x M x P
%              delays (s) of every channel to a block of points; the delays
%              are used both to align the signals and to rank the channels.
%   Output:
%     img      P x 1 image values.
%
%   Reference: M. O'Halloran, M. Glavin and E. Jones, "Channel-ranked
%   beamformer for the early detection of breast cancer", Progress In
%   Electromagnetics Research 103, 153-168, 2010, doi:10.2528/PIER10030902.
%
%   Example:
%     delays = merit.get_delay(channel_names, antenna_locations, relative_permittivity=8);
%     img = abs(merit.beamformer.channel_ranked_das(signals, frequencies, points, delays));
%
%   See also merit.beamform, merit.beamformer.DAS, merit.get_delay.
arguments
    signals {mustBeNumeric}
    axis_ (:,1) {mustBeNumeric, mustBeReal}
    points (:,:) {mustBeNumeric, mustBeReal}
    delay (1,1) function_handle
    options.window (1,1) function_handle = @(a) a
    options.max_memory (1,1) {mustBeNumeric, mustBePositive} = 1e9
end
error('merit:beamformer:channel_ranked_das:notImplemented', 'channel_ranked_das is not implemented yet.');
end
```
