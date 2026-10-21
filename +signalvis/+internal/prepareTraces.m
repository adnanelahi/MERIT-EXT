function [data,qnames] = prepareTraces(A,inputType,quantity,inputMagScale,magScale,inputPhaseUnits,phaseUnits,unwrapPhase,dbFloor)
%PREPARETRACES Convert a samples-by-traces array without creating graphics.
% This is shared by signalViewer and inspectPointDelays.
data=cell(1,2);
qnames={};
if any(strcmp(quantity,{'magnitude','both'}))
    if strcmp(inputType,'magnitude')
        M=double(A);
    else
        M=abs(A);
    end
    if strcmp(magScale,'db') && ~(strcmp(inputType,'magnitude') && strcmpi(inputMagScale,'db'))
        finiteSamples=isfinite(M);
        M(finiteSamples)=max(20*log10(M(finiteSamples)),dbFloor);
    elseif strcmp(inputType,'magnitude') && strcmpi(inputMagScale,'db') && strcmpi(magScale,'linear')
        finiteSamples=isfinite(M);
        M(finiteSamples)=10.^(M(finiteSamples)/20);
    end
    data{1}=M;
    qnames{end+1}=magnitudeLabel(magScale);
end
if any(strcmp(quantity,{'phase','both'}))
    if strcmp(inputType,'phase')
        P=double(A);
        inputUnits=lower(inputPhaseUnits);
    else
        P=angle(A);
        P(~(isfinite(real(A)) & isfinite(imag(A))))=NaN;
        inputUnits='radians';
    end
    if unwrapPhase
        if strcmp(inputUnits,'degrees')
            P=P*pi/180;
        end
        P=unwrapFiniteRuns(P);
        inputUnits='radians';
    end
    if strcmp(inputUnits,'radians') && strcmp(phaseUnits,'degrees')
        P=P*180/pi;
    elseif strcmp(inputUnits,'degrees') && strcmp(phaseUnits,'radians')
        P=P*pi/180;
    end
    data{numel(qnames)+1}=P;
    qnames{end+1}=['Phase (' phaseUnits ')'];
end
if strcmp(quantity,'value')
    data{1}=double(A);
    if strcmp(inputType,'magnitude')
        qnames={magnitudeLabel(inputMagScale)};
    elseif strcmp(inputType,'phase')
        qnames={['Phase (' lower(inputPhaseUnits) ')']};
    else
        qnames={'Value'};
    end
end
data=data(1:numel(qnames));
end

function P=unwrapFiniteRuns(P)
for c=1:size(P,2)
    valid=isfinite(P(:,c));
    edges=diff([false;valid;false]);
    starts=find(edges==1);
    stops=find(edges==-1)-1;
    for j=1:numel(starts)
        ix=starts(j):stops(j);
        P(ix,c)=unwrap(P(ix,c));
    end
end
end

function label=magnitudeLabel(scale)
if strcmpi(scale,'db')
    label='Magnitude (dB)';
else
    label='Magnitude (linear)';
end
end
