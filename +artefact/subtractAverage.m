function [cleaned, info] = subtractAverage(signals, references, varargin)
%SUBTRACTAVERAGE Remove the artefact by subtracting the average of reference channels.
%   CLEANED = artefact.subtractAverage(SIGNALS, REFERENCES) subtracts from
%   each channel c the mean of the channels REFERENCES{c}:
%       CLEANED(:,c,...) = SIGNALS(:,c,...) - mean(SIGNALS(:,REFERENCES{c},...), 2)
%   SIGNALS has samples in dimension 1 and channels in dimension 2, as in
%   MERIT, and may be complex frequency-domain or real time-domain data;
%   further dimensions are processed in the same way. REFERENCES is the
%   C-by-1 cell array from artefact.referenceChannels, or the structure
%   returned by neighbourhoodEditor's GetResult.
%   CLEANED = artefact.subtractAverage(..., 'Empty', MODE) sets what happens
%   to a channel without reference channels: 'keep' (default) leaves it
%   unchanged, 'zero' sets it to zero.
%   [CLEANED, INFO] = ... also returns INFO.NoReference, the channels
%   without reference channels.
%   Example:
%     n = artefact.antennaNeighbours(antenna_locations, channel_names, 'Distance', 0.09);
%     references = artefact.referenceChannels(n, channel_names);
%     cleaned = artefact.subtractAverage(scan, references);

if nargin<2
    error('artefact:subtractAverage:NotEnoughInputs','Signals and references are required.');
end
if ~(isnumeric(signals)&&(isa(signals,'single')||isa(signals,'double'))&&~isempty(signals))
    error('artefact:subtractAverage:Signals','Signals must be a nonempty single or double array.');
end
C=size(signals,2);
if isstruct(references)&&isfield(references,'References'), references=references.References; end
if ~(iscell(references)&&numel(references)==C)
    error('artefact:subtractAverage:References','References must list the reference channels of each of the %d channels.',C);
end
for c=1:C
    r=references{c};
    if ~(isempty(r)||(isnumeric(r)&&isreal(r)&&isvector(r)&&all(r==round(r))&&all(r>=1)&&all(r<=C)))
        error('artefact:subtractAverage:References','Reference channels of channel %d must be channel numbers from 1 to %d.',c,C);
    end
end
p=inputParser; p.FunctionName='artefact.subtractAverage';
addParameter(p,'Empty','keep');
parse(p,varargin{:});
mode=p.Results.Empty;
if isstring(mode)&&isscalar(mode), mode=char(mode); end
if ~(ischar(mode)&&any(strcmpi(mode,{'keep','zero'})))
    error('artefact:subtractAverage:Empty','Empty must be keep or zero.');
end

shape=size(signals);
flat=reshape(signals,shape(1),C,[]);
out=flat;
empty=false(1,C);
for c=1:C
    r=unique(double(references{c}(:)).');
    if isempty(r)
        empty(c)=true;
        if strcmpi(mode,'zero'), out(:,c,:)=0; end
    else
        out(:,c,:)=flat(:,c,:)-mean(flat(:,r,:),2);
    end
end
cleaned=reshape(out,shape);
info=struct('NoReference',find(empty));
end
