function pairs=validatePairs(pairs,N,id)
%VALIDATEPAIRS Return channel pairs as a C-by-2 double array of antenna numbers.
if isempty(pairs), pairs=zeros(0,2); end
if ~(isnumeric(pairs)&&isreal(pairs)&&ismatrix(pairs)&&size(pairs,2)==2 ...
        &&all(pairs(:)==round(pairs(:)))&&all(pairs(:)>=1)&&all(pairs(:)<=N))
    error(id,'Channel pairs must be a C-by-2 array of antenna numbers between 1 and %d.',N);
end
pairs=double(pairs);
end
