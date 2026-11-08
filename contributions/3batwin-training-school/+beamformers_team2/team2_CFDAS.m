function process_signals = team2_CFDAS(options)
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
process_signals = @process;

    function energies = process(delayed)
        % delayed: N x C x P delayed signals; values: P x 1 image values.


        % Coherence-factor weighted DAS (Klemm et al., IEEE AWPL 2009).

        n_channels = size(delayed_signals, 2);
        % DAS energy: |sum over channels|^2, summed over the window
        e_of_sum = sum(abs(sum(delayed_signals, 2)).^2, 1);
        % Total energy of the individual channels, summed over the window
        sum_of_e = sum(sum(abs(delayed_signals).^2, 1), 2);
        % Coherence factor in [0, 1]
        CF = e_of_sum ./ (n_channels .* sum_of_e);
        CF(sum_of_e == 0) = 0;
        energies = shiftdim(e_of_sum .* CF, 2);

        error('merit:beamformer:CFDAS:notImplemented', 'CFDAS is not implemented yet.');
    end
end