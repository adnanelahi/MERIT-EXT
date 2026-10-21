function candidates=candidateNeighbours(pairs,N,measuredOnly)
%CANDIDATENEIGHBOURS N-by-N logical matrix; (i,m) true if m may be a neighbour of i.
% With measuredOnly, m qualifies when a channel between i and m is measured
% in either direction, or, for monostatic channels, when m has its own
% measured channel m-m and i has i-i.
if ~measuredOnly
    candidates=true(N);
else
    candidates=false(N);
    if ~isempty(pairs)
        index=sub2ind([N N],pairs(:,1),pairs(:,2));
        candidates(index)=true;
        candidates=candidates|candidates.';
        own=false(1,N);
        mono=pairs(:,1)==pairs(:,2);
        own(pairs(mono,1))=true;
        candidates=candidates|(own.'&own);
    end
end
candidates(1:N+1:end)=false;
end
