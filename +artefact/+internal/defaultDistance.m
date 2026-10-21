function limit=defaultDistance(locations,candidates)
%DEFAULTDISTANCE Default neighbourhood distance: 1.2 times the largest nearest-candidate distance.
% Every antenna with at least one candidate then has its nearest candidate
% within the distance. Without any candidates the distance is 0.
N=size(locations,1);
nearest=NaN(1,N);
for a=1:N
    pool=find(candidates(a,:));
    if ~isempty(pool)
        nearest(a)=min(sqrt(sum((locations(pool,:)-locations(a,:)).^2,2)));
    end
end
if all(isnan(nearest))
    limit=0;
else
    limit=1.2*max(nearest(~isnan(nearest)));
end
end
