function locations=validateLocations(locations,id)
%VALIDATELOCATIONS Return antenna locations as an N-by-3 double array.
if ~(isnumeric(locations)&&isreal(locations)&&ismatrix(locations)&&any(size(locations,2)==[2 3]) ...
        &&size(locations,1)>=1&&all(isfinite(locations(:))))
    error(id,'Antenna locations must be a finite real N-by-3 (or N-by-2) array.');
end
locations=double(locations);
if size(locations,2)==2, locations(:,3)=0; end
end
