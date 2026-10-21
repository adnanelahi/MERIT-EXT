function neighbours = antennaNeighbours(locations, channelPairs, varargin)
%ANTENNANEIGHBOURS Neighbourhood of each antenna from the antenna positions.
%   NEIGHBOURS = artefact.antennaNeighbours(LOCATIONS, CHANNELPAIRS, METHOD,
%   Name,Value,...) returns an N-by-1 cell array; element i lists the
%   neighbours of antenna i in ascending order of antenna number. The
%   nearest are chosen by distance, ties going to the lower antenna number.
%   An antenna is never its own neighbour. LOCATIONS is N-by-3 and
%   CHANNELPAIRS is MERIT's C-by-2 channel_names array (Tx, Rx).
%   Methods (METHOD may be omitted; the default is 'distance'):
%     'distance'  all candidates within Distance (units of LOCATIONS); the
%                 default Distance is 1.2 times the largest distance from
%                 an antenna to its nearest candidate
%     'nearest'   the K closest candidates (option K, required)
%   Options:
%     Antennas      antennas whose neighbourhoods are computed (default
%                   all); the others receive an empty neighbourhood
%     MeasuredOnly  true (default): candidates for antenna i are the
%                   antennas sharing a measured channel with i in either
%                   direction; for monostatic channels (m-m), the antennas
%                   with their own measured channel. false: all antennas.
%   Examples:
%     neighbours = artefact.antennaNeighbours(antenna_locations, channel_names);
%     neighbours = artefact.antennaNeighbours(antenna_locations, channel_names, 'Distance', 0.09);
%     neighbours = artefact.antennaNeighbours(antenna_locations, channel_names, 'nearest', 'K', 2);

if nargin<2
    error('artefact:antennaNeighbours:NotEnoughInputs','Locations and channel pairs are required.');
end
% An odd number of further arguments means that a method comes first.
if mod(numel(varargin),2)==1
    method=varargin{1}; varargin=varargin(2:end);
else
    method='distance';
end
locations=artefact.internal.validateLocations(locations,'artefact:antennaNeighbours:Locations');
N=size(locations,1);
channelPairs=artefact.internal.validatePairs(channelPairs,N,'artefact:antennaNeighbours:ChannelPairs');
method=lower(textValue(method,'Method'));

p=inputParser; p.FunctionName='artefact.antennaNeighbours';
addParameter(p,'K',[]); addParameter(p,'Distance',[]); addParameter(p,'Antennas',1:N);
addParameter(p,'MeasuredOnly',true);
parse(p,varargin{:}); o=p.Results;

antennas=o.Antennas;
if ~(isnumeric(antennas)&&isreal(antennas)&&(isvector(antennas)||isempty(antennas))&&all(antennas(:)==round(antennas(:))) ...
        &&all(antennas(:)>=1)&&all(antennas(:)<=N))
    error('artefact:antennaNeighbours:Antennas','Antennas must contain antenna numbers between 1 and %d.',N);
end
antennas=unique(double(antennas(:)).');
if ~((islogical(o.MeasuredOnly)||isnumeric(o.MeasuredOnly))&&isscalar(o.MeasuredOnly))
    error('artefact:antennaNeighbours:MeasuredOnly','MeasuredOnly must be true or false.');
end
switch method
    case 'nearest'
        K=o.K;
        if ~(isnumeric(K)&&isreal(K)&&isscalar(K)&&K>=0&&K==round(K))
            error('artefact:antennaNeighbours:K','K must be a nonnegative integer.');
        end
    case 'distance'
        limit=o.Distance;
        if isempty(limit)
            limit=artefact.internal.defaultDistance(locations, ...
                artefact.internal.candidateNeighbours(channelPairs,N,logical(o.MeasuredOnly)));
        end
        if ~(isnumeric(limit)&&isreal(limit)&&isscalar(limit)&&isfinite(limit)&&limit>=0)
            error('artefact:antennaNeighbours:Distance','Distance must be a finite nonnegative scalar.');
        end
    otherwise
        error('artefact:antennaNeighbours:Method','Method must be nearest or distance.');
end

candidates=artefact.internal.candidateNeighbours(channelPairs,N,logical(o.MeasuredOnly));
neighbours=cell(N,1);
for i=1:N, neighbours{i}=zeros(1,0); end
for i=antennas
    pool=find(candidates(i,:));
    if isempty(pool), continue; end
    d=sqrt(sum((locations(pool,:)-locations(i,:)).^2,2)).';
    [~,order]=sortrows([d(:) pool(:)]);
    pool=pool(order); d=d(order);
    if strcmp(method,'nearest')
        neighbours{i}=sort(pool(1:min(K,numel(pool))));
    else
        neighbours{i}=sort(pool(d<=limit));
    end
end
end

function value=textValue(value,name)
if isstring(value)&&isscalar(value), value=char(value); end
if ~(ischar(value)&&isrow(value))
    error(['artefact:antennaNeighbours:' name],'%s must be text.',name);
end
end
