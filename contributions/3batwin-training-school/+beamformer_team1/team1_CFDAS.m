function [process_signals] = team1_CFDAS()
  % Assumes window x channel x points x ...

  function [energies] = process_(delayed_signals),
    %e_of_sum = shiftdim(sum(sum(delayed_signals, 2).^2, 1), 2);
    e_of_sum = sum(sum(delayed_signals, 2).^2, 1);
    sum_of_e = sum(sum(delayed_signals.^2, 1), 2);
    N = size(delayed_signals,2);
    CF = e_of_sum./sum_of_e;
    CF = CF./N;
    energies = shiftdim(e_of_sum.*CF, 2);
  end
  process_signals = @process_;
end

