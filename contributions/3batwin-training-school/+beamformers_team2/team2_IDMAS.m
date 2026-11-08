function [process_signals] = team2_IDMAS(iterations)
  % Iterative Delay-Multiply-and-Sum.
  %
  % DMAS can be written as  sum_{i<j} x_i x_j = sum_i x_i * DAS(x_{i+1..N}).
  % Each iteration replaces the inner DAS with the previous stage, so
  %   stage 0 :  S0(i) = sum_{j>=i} x_j         (DAS)
  %   stage k :  Sk(i) = sum_{m>=i} x_m * S{k-1}(m+1)
  % iterations = 1 gives DMAS, iterations = 2 gives double-stage DMAS, etc.
  if nargin < 1
    iterations = 1;
  end
  function [energies] = process_(dsig),
    sz = size(dsig);
    nChannels = sz(2);
    if iterations >= nChannels
      error('IDMAS: iterations must be smaller than the number of channels.');
    end
    x = reshape(dsig, sz(1), nChannels, []);
    % Stage 0: DAS
    s = suffixsum(x);
    for k = 1:iterations
      shifted = cat(2, s(:, 2:end, :), zeros(sz(1), 1, size(x, 3), 'like', x));
      s = suffixsum(x.*shifted);
    end
    tmp = reshape(s(:, 1, :), [sz(1), 1, sz(3:end)]);
    energies = shiftdim(sum(tmp.^2, 1), 2);
  end
  process_signals = @process_;
end
function [s] = suffixsum(x)
  s = flip(cumsum(flip(x, 2), 2), 2);
end