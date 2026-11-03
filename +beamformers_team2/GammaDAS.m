function [process_signals] = GammaDAS(gamma)
  % DAS followed by a Gamma (power-law) transformation.
  %
  % Each pixel of the DAS image is raised to the power gamma. Paper for
  % reference: "Real-Time Super-Resolution Microwave Imaging Using Gamma Transformation",
  % The n-th order nonlinear beamformer is approximated by gamma = 2^(n-1):
  % gamma = 1 is DAS, gamma = 2 ~ DMAS, gamma = 4, 8, 16 ~ higher orders.
  if nargin < 1
    gamma = 2;
  end
  function [energies] = process_(delayed_signals)
    energies = shiftdim(sum(sum(delayed_signals, 2).^2, 1), 2).^gamma;
  end
  process_signals = @process_;
end