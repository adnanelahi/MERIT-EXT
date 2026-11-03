function [process_signals] = our_CRDAS()

    function [energies] = process_(delayed_signals)
        
    N = size(delayed_signals,2); % number of channels
    pixel_num = size(delayed_signals,3); %number of pixels
    
    [~, rank] = sort(abs(delayed_signals),3,'ascend');
    %rank = rescale(rank,1,N);
    w = (N-rank)./(N*((N+1)/2));
    
    energies = shiftdim(sum(sum(w.*delayed_signals, 2).^2, 1), 2);
    end

process_signals = @process_;
end