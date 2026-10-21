function [references, info] = referenceChannels(neighbours, channelPairs, varargin)
%REFERENCECHANNELS Reference channels of each channel from antenna neighbourhoods.
%   REFERENCES = artefact.referenceChannels(NEIGHBOURS, CHANNELPAIRS,
%   Name,Value,...) returns a C-by-1 cell array; element c lists the
%   channels (rows of CHANNELPAIRS) whose average is the reference for
%   channel c in average subtraction. NEIGHBOURS is the N-by-1 cell array
%   from artefact.antennaNeighbours; CHANNELPAIRS is MERIT's C-by-2
%   channel_names array (Tx, Rx). Measurements are treated as reciprocal:
%   a measured channel a-b also serves as b-a.
%   For channel i-j (i transmits, j receives):
%     Rule 'receiver' (default)  channels i-m for neighbours m of j
%     Rule 'transmitter'         channels i-m for neighbours m of i
%   For a monostatic channel i-i, both rules give the channels m-m for the
%   neighbours m of i.
%   Options: Rule, IncludeSelf (false: the channel is left out of its own
%   reference; true: it is included).
%   [REFERENCES, INFO] = ... also returns INFO with fields NoReference
%   (channels with an empty reference) and Missing (C-by-1 cell; element c
%   lists, as rows [Tx Rx], channels needed for channel c but not measured).
%   Example:
%     n = artefact.antennaNeighbours(antenna_locations, channel_names);
%     references = artefact.referenceChannels(n, channel_names);

if nargin<2
    error('artefact:referenceChannels:NotEnoughInputs','Neighbours and channel pairs are required.');
end
if ~iscell(neighbours)
    error('artefact:referenceChannels:Neighbours','Neighbours must be a cell array with one element per antenna.');
end
neighbours=neighbours(:);
N=numel(neighbours);
for i=1:N
    m=neighbours{i};
    if ~(isempty(m)||(isnumeric(m)&&isreal(m)&&isvector(m)&&all(m==round(m))&&all(m>=1)&&all(m<=N)&&~any(m==i)))
        error('artefact:referenceChannels:Neighbours','Neighbours of antenna %d must be antenna numbers from 1 to %d, excluding %d.',i,N,i);
    end
    neighbours{i}=unique(double(m(:)).');
end
channelPairs=artefact.internal.validatePairs(channelPairs,N,'artefact:referenceChannels:ChannelPairs');
C=size(channelPairs,1);

p=inputParser; p.FunctionName='artefact.referenceChannels';
addParameter(p,'Rule','receiver'); addParameter(p,'IncludeSelf',false);
parse(p,varargin{:}); o=p.Results;
rule=o.Rule;
if isstring(rule)&&isscalar(rule), rule=char(rule); end
if ~(ischar(rule)&&any(strcmpi(rule,{'receiver','transmitter'})))
    error('artefact:referenceChannels:Rule','Rule must be receiver or transmitter.');
end
rule=lower(rule);
if ~((islogical(o.IncludeSelf)||isnumeric(o.IncludeSelf))&&isscalar(o.IncludeSelf))
    error('artefact:referenceChannels:IncludeSelf','IncludeSelf must be true or false.');
end

% Channel number of each ordered antenna pair; reciprocal pairs are filled
% only where the ordered pair itself is not measured.
lookup=zeros(N);
for c=C:-1:1
    lookup(channelPairs(c,2),channelPairs(c,1))=c;
end
for c=C:-1:1
    lookup(channelPairs(c,1),channelPairs(c,2))=c;
end

references=cell(C,1); missing=cell(C,1);
for c=1:C
    i=channelPairs(c,1); j=channelPairs(c,2);
    if i==j
        wanted=[neighbours{i}(:) neighbours{i}(:)];
    elseif strcmp(rule,'receiver')
        m=neighbours{j}; m(m==i)=[];   % the transmitter is not its own receiver
        wanted=[repmat(i,numel(m),1) m(:)];
    else
        m=neighbours{i}; wanted=[repmat(i,numel(m),1) m(:)];
    end
    found=zeros(1,size(wanted,1));
    for k=1:size(wanted,1), found(k)=lookup(wanted(k,1),wanted(k,2)); end
    missing{c}=wanted(found==0,:);
    chosen=unique(found(found>0));
    if o.IncludeSelf, chosen=unique([chosen c]); else, chosen(chosen==c)=[]; end
    references{c}=chosen;
end
info=struct('NoReference',find(cellfun(@isempty,references)).','Missing',{missing});
end
