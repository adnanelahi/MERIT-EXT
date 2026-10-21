function [fig,inspector] = inspectPointDelays(signals,sampleAxis,points,delays,varargin)
%INSPECTPOINTDELAYS Compare original MERIT signals with one focused point.
%   The signals are the samples-by-channels matrix supplied to MERIT's
%   beamformer. Points are P-by-3 coordinates; delay handles are called with
%   one point at a time in metres. The returned inspector provides
%   SelectPoint, SelectSlice and GetSelection function handles.

if nargin<4
    error('signalvis:inspectPointDelays:NotEnoughInputs','Signals, sample axis, points and delays are required.');
end

if ~(isnumeric(signals)&&(isa(signals,'single')||isa(signals,'double'))&&ismatrix(signals)&&~isempty(signals))
    error('signalvis:inspectPointDelays:Signals','Signals must be a nonempty single or double samples-by-channels matrix.');
end
if ~(isnumeric(sampleAxis)&&isreal(sampleAxis)&&isvector(sampleAxis)&&numel(sampleAxis)==size(signals,1)&&all(isfinite(sampleAxis(:)))&&all(diff(sampleAxis(:))>0))
    error('signalvis:inspectPointDelays:SampleAxis','SampleAxis must be finite, increasing and match the sample count.');
end
if ~(isnumeric(points)&&isreal(points)&&ismatrix(points)&&size(points,2)==3&&~isempty(points)&&all(isfinite(points(:))))
    error('signalvis:inspectPointDelays:Points','Points must be a finite P-by-3 real array.');
end
if size(unique(points,'rows'),1)~=size(points,1)
    error('signalvis:inspectPointDelays:Points','Points must be unique.');
end
if ~(isa(delays,'function_handle')||isnumeric(delays))
    error('signalvis:inspectPointDelays:Delays','Delays must be a function handle or numeric delay array.');
end

p=inputParser;
addParameter(p,'Domain','auto'); addParameter(p,'AxisUnits',''); addParameter(p,'DisplayAxisUnits','');
addParameter(p,'CoordinateUnits','m'); addParameter(p,'DisplayCoordinateUnits','');
addParameter(p,'DelayUnits','s'); addParameter(p,'SampleInterval',[]);
addParameter(p,'Image',[]); addParameter(p,'ImageIndex',[]); addParameter(p,'ImageComponent','auto');
addParameter(p,'Axes',[]); addParameter(p,'SliceZ',[]); addParameter(p,'InitialPoint',[]);
addParameter(p,'Window',[]); addParameter(p,'WindowAxis',[]);
addParameter(p,'Channels',[]); addParameter(p,'ChannelLabels',[]); addParameter(p,'TraceLabels',[]);
addParameter(p,'Quantity','auto'); addParameter(p,'MagnitudeScale','linear'); addParameter(p,'DBFloor',-300);
addParameter(p,'PhaseUnits','radians'); addParameter(p,'UnwrapPhase',false);
addParameter(p,'Layout','overlay'); addParameter(p,'ChannelsPerPage',4); addParameter(p,'Legend','auto');
addParameter(p,'Title',''); addParameter(p,'Visible','on');
parse(p,varargin{:}); o=p.Results;
channelsOmitted=any(strcmp('Channels',p.UsingDefaults));
textOptions={'Domain','AxisUnits','DisplayAxisUnits','CoordinateUnits','DisplayCoordinateUnits', ...
    'DelayUnits','ImageComponent','Quantity','MagnitudeScale','PhaseUnits','Layout','Legend','Visible','Title'};
for k=1:numel(textOptions)
    value=o.(textOptions{k});
    if ~(ischar(value)&&(isrow(value)||isempty(value)))&&~(isstring(value)&&isscalar(value))
        error(['signalvis:inspectPointDelays:' textOptions{k}],'%s must be text.',textOptions{k});
    end
end

[cfg,initial] = validateAndPrepare(signals,sampleAxis,points,delays,o,channelsOmitted);

% Validate initial signal rendering before allocating a figure.
originalView=viewsFor(signals,cfg,o);
delayedView=viewsFor(initial.DelayedSignals,cfg,o);
if ~isempty(o.Window), windowView=viewsFor(initial.ComparedSignals,cfg,o); else, windowView={}; end

fig=figure('Visible',char(o.Visible),'Name','MERIT point delay inspector','NumberTitle','off');
set(fig,'Units','normalized','Position',[.08 .08 .84 .82]);
setappdata(fig,'signalvisPage',1);
handles=makeLayout(fig,cfg,o,numel(cfg.channels));
inspector=struct();
inspector.MapAxes=handles.MapAxes;
inspector.OriginalAxes=handles.OriginalAxes;
inspector.DelayedAxes=handles.DelayedAxes;
inspector.WindowedAxes=handles.WindowedAxes;
inspector.SliceControl=handles.SliceControl;
inspector.PreviousPage=handles.PreviousPage;
inspector.NextPage=handles.NextPage;
inspector.PageText=handles.PageText;
inspector.Status=handles.Status;
inspector.SelectPoint=@selectPoint;
inspector.SelectSlice=@selectSlice;
inspector.GetSelection=@getSelection;
setappdata(fig,'signalvisInspector',true);
set(handles.MapAxes,'ButtonDownFcn',@onMapClick);
if ~isempty(handles.SliceControl), set(handles.SliceControl,'Callback',@onSliceChange); end
if ~isempty(handles.PreviousPage), set(handles.PreviousPage,'Callback',@(~,~)changePage(-1)); end
if ~isempty(handles.NextPage), set(handles.NextPage,'Callback',@(~,~)changePage(1)); end
state=initial;
renderMap(initial.PointIndex);
drawComparison(originalView,delayedView,windowView,cfg.calcAxis,cfg.calcAxis,initial.ComparedAxis,cfg.Page);
setStatus(selectionStatus(initial,cfg));

    function result=getSelection()
        result=state;
    end

    function selectPoint(index)
        selectPointInternal(index,false);
    end

    function selectPointInternal(index,fromUI)
        try
            if ~isnumeric(index)||~isreal(index)||~isscalar(index)||~isfinite(index)||index<1||index>size(points,1)||index~=fix(index)
                error('signalvis:inspectPointDelays:PointIndex','Point index must be an integer from 1 to %d.',size(points,1));
            end
            candidate=calculateSelection(index,cfg,o,signals,points,delays);
            newOriginal=viewsFor(candidate.OriginalSignals,cfg,o);
            newDelayed=viewsFor(candidate.DelayedSignals,cfg,o);
            if ~isempty(o.Window), newWindow=viewsFor(candidate.ComparedSignals,cfg,o); else, newWindow={}; end
            candidate.Page=cfg.Page;
            updateSliceControl(candidate.SliceZ*cfg.coordFactor);
            renderMap(candidate.PointIndex);
            drawComparison(newOriginal,newDelayed,newWindow,cfg.calcAxis,cfg.calcAxis,candidate.ComparedAxis,cfg.Page);
            state=candidate;
            setStatus(selectionStatus(candidate,cfg));
        catch err
            if fromUI
                if exist('state','var')&&~isempty(state)
                    updateSliceControl(state.SliceZ*cfg.coordFactor);
                end
                setStatus(err.message);
            else
                rethrow(err);
            end
        end
    end

    function selectSlice(z)
        selectSliceInternal(z,false);
    end

    function selectSliceInternal(z,fromUI)
        try
            if ~isnumeric(z)||~isreal(z)||~isscalar(z)||~isfinite(z)
                error('signalvis:inspectPointDelays:SliceZ','SliceZ must be a finite real scalar.');
            end
            [~,ix]=min(abs(cfg.UniqueZ-z*cfg.coordFactor));
            rows=find(abs(cfg.pointsM(:,3)-cfg.UniqueZ(ix))<=cfg.zTolerance);
            if isempty(rows), error('signalvis:inspectPointDelays:Slice','No points are available on the selected plane.'); end
            selectPointInternal(rows(1),fromUI);
        catch err
            if fromUI
                setStatus(err.message);
            else
                rethrow(err);
            end
        end
    end

    function changePage(step)
        newPage=max(1,min(cfg.Pages,cfg.Page+step));
        if newPage==cfg.Page, return; end
        cfg.Page=newPage;
        state.Page=newPage;
        setappdata(fig,'signalvisPage',newPage);
        drawComparison(viewsFor(state.OriginalSignals,cfg,o),viewsFor(state.DelayedSignals,cfg,o), ...
            optionalViews(state.ComparedSignals,cfg,o),state.CalculationAxis,state.CalculationAxis,state.ComparedAxis,cfg.Page);
        updatePageControls();
    end

    function onMapClick(~,~)
        pt=get(handles.MapAxes,'CurrentPoint');
        target=[pt(1,1) pt(1,2)]*cfg.displayCoordFactor;
        target(3)=cfg.UniqueZ(currentPlaneIndex());
        candidates=find(abs(cfg.pointsM(:,3)-target(3))<=cfg.zTolerance);
        d=sum((cfg.pointsM(candidates,1:2)-target(1:2)).^2,2);
        [~,ix]=min(d);
        selectPointInternal(candidates(ix),true);
    end

    function onSliceChange(~,~)
        ix=get(handles.SliceControl,'Value');
        z=cfg.UniqueZ(ix)/cfg.coordFactor;
        selectSliceInternal(z,true);
    end

    function index=currentPlaneIndex()
        [~,index]=min(abs(cfg.UniqueZ-state.SliceZ*cfg.coordFactor));
    end

    function updateSliceControl(zM)
        if isempty(handles.SliceControl), return; end
        [~,ix]=min(abs(cfg.UniqueZ-zM));
        set(handles.SliceControl,'Value',ix);
    end

    function updatePageControls()
        if isempty(handles.PreviousPage), return; end
        if cfg.Page<=1, set(handles.PreviousPage,'Enable','off'); else, set(handles.PreviousPage,'Enable','on'); end
        if cfg.Page>=cfg.Pages, set(handles.NextPage,'Enable','off'); else, set(handles.NextPage,'Enable','on'); end
        set(handles.PageText,'String',sprintf('Page %d of %d',cfg.Page,cfg.Pages));
    end

    function renderMap(pointIndex)
        renderPointMap(handles.MapAxes,cfg,pointIndex,o);
    end

    function drawComparison(originalData,delayedData,windowData,originalAxis,delayedAxis,windowAxis,page)
        renderComparison(handles.OriginalAxes,originalData,originalAxis,cfg,o,page,'Original');
        delayedName='Delayed';
        if isempty(o.Window), delayedName='Delayed (before windowing)'; end
        renderComparison(handles.DelayedAxes,delayedData,delayedAxis,cfg,o,page,delayedName);
        if ~isempty(handles.WindowedAxes)
            renderComparison(handles.WindowedAxes,windowData,windowAxis,cfg,o,page,'Windowed');
        end
        updatePageControls();
    end

    function setStatus(message)
        if ~isempty(handles.Status)&&ishghandle(handles.Status), set(handles.Status,'String',message); end
        drawnow; % Complete the window even if a script continues with a long computation.
    end

end

function [cfg,initial]=validateAndPrepare(signals,axis,points,delays,o,channelsOmitted)
if isempty(which('merit.process.delay'))
    error('signalvis:inspectPointDelays:MERITMissing','MERIT''s merit.process.delay must be on the MATLAB path.');
end
if isempty(o.AxisUnits)
    if isreal(signals), axisUnits='s'; else, axisUnits='hz'; end
else
    axisUnits=lowerText(o.AxisUnits,'AxisUnits');
end
timeUnits={'s','ms','us','ns','ps'};
frequencyUnits={'hz','khz','mhz','ghz'};
sampleUnits={'samples'};
if ~any(strcmp(axisUnits,[timeUnits frequencyUnits sampleUnits]))
    error('signalvis:inspectPointDelays:AxisUnits','AxisUnits must be time, frequency, or samples.');
end
domain=lowerText(o.Domain,'Domain');
if strcmp(domain,'auto')
    if any(strcmp(axisUnits,frequencyUnits)), domain='frequency'; else, domain='time'; end
end
if ~any(strcmp(domain,{'time','frequency'}))
    error('signalvis:inspectPointDelays:Domain','Domain must be auto, time or frequency.');
end
imageComponent=lowerText(o.ImageComponent,'ImageComponent');
if ~any(strcmp(imageComponent,{'auto','magnitude','real','imaginary'}))
    error('signalvis:inspectPointDelays:ImageComponent','ImageComponent must be auto, magnitude, real or imaginary.');
end
if isempty(o.Image)&&~isempty(o.ImageIndex)
    error('signalvis:inspectPointDelays:ImageIndex','ImageIndex is only used with Image.');
end
if strcmp(domain,'time')
    if ~isreal(signals), error('signalvis:inspectPointDelays:Domain','MERIT time-delay processing requires real signals.'); end
    if ~any(strcmp(axisUnits,[timeUnits sampleUnits])), error('signalvis:inspectPointDelays:Domain','Time-domain signals require time or samples axis units.'); end
else
    if isreal(signals), error('signalvis:inspectPointDelays:Domain','MERIT frequency-delay processing requires non-real complex signals; MERIT treats real arrays as time data.'); end
    if ~any(strcmp(axisUnits,frequencyUnits)), error('signalvis:inspectPointDelays:Domain','Frequency-domain signals require frequency axis units.'); end
end
sampleInterval=[];
if ~isempty(o.SampleInterval)
    sampleInterval=o.SampleInterval;
    if ~isnumeric(sampleInterval)||~isreal(sampleInterval)||~isscalar(sampleInterval)||~isfinite(sampleInterval)||sampleInterval<=0
        error('signalvis:inspectPointDelays:SampleInterval','SampleInterval must be a finite positive number of seconds.');
    end
end
if strcmp(axisUnits,'samples')
    if isempty(sampleInterval), error('signalvis:inspectPointDelays:SampleInterval','SampleInterval in seconds is required when AxisUnits is samples.'); end
    calcAxis=double(axis(:))*sampleInterval;
    dt=diff(calcAxis);
else
    factor=unitFactor(axisUnits);
    calcAxis=double(axis(:))*factor;
    if strcmp(domain,'time'), dt=diff(calcAxis); else, dt=[]; end
end
if any(~isfinite(calcAxis))||any(diff(calcAxis)<=0)
    error('signalvis:inspectPointDelays:SampleAxis','Converted SI sample coordinates must be finite and increasing.');
end
if strcmp(domain,'time')
    if numel(calcAxis)<2, error('signalvis:inspectPointDelays:SampleAxis','Time data needs at least two samples.'); end
    scale=max(abs(dt));
    if max(abs(dt-mean(dt)))>max(eps(scale)*64,scale*1e-8)
        error('signalvis:inspectPointDelays:SampleAxis','Time axes must be uniformly spaced for MERIT delay processing.');
    end
    dt=mean(dt);
else
    dt=[];
end
displayAxisUnits=axisUnits;
if ~isempty(o.DisplayAxisUnits), displayAxisUnits=lowerText(o.DisplayAxisUnits,'DisplayAxisUnits'); end
if strcmp(axisUnits,'samples')
    if ~strcmp(displayAxisUnits,'samples'), error('signalvis:inspectPointDelays:DisplayAxisUnits','Sample axes must be displayed in samples.'); end
elseif strcmp(domain,'time')
    if ~any(strcmp(displayAxisUnits,timeUnits)), error('signalvis:inspectPointDelays:DisplayAxisUnits','Time display units must be s, ms, us, ns or ps.'); end
else
    if ~any(strcmp(displayAxisUnits,frequencyUnits)), error('signalvis:inspectPointDelays:DisplayAxisUnits','Frequency display units must be Hz, kHz, MHz or GHz.'); end
end
coordUnits=lowerText(o.CoordinateUnits,'CoordinateUnits');
coordFactor=coordinateFactor(coordUnits);
displayCoordUnits=coordUnits;
if ~isempty(o.DisplayCoordinateUnits), displayCoordUnits=lowerText(o.DisplayCoordinateUnits,'DisplayCoordinateUnits'); end
coordinateFactor(displayCoordUnits);
delayUnits=lowerText(o.DelayUnits,'DelayUnits');
if ~any(strcmp(delayUnits,{'s','ns','samples'})), error('signalvis:inspectPointDelays:DelayUnits','DelayUnits must be s, ns or samples.'); end
if strcmp(delayUnits,'samples')&&(strcmp(domain,'frequency')||isempty(dt))
    error('signalvis:inspectPointDelays:DelayUnits','Sample delays require time-domain data with a known sample interval.');
end
if isa(delays,'function_handle')
    numericDelays=[];
else
    numericDelays=normaliseDelays(delays,size(signals,2),size(points,1));
end

pointsM=double(points)*coordFactor;
uniqueZ=unique(pointsM(:,3),'stable');
zTolerance=max(eps(max(abs(uniqueZ)))*64,1e-12);
if isempty(o.SliceZ), chosenZ=uniqueZ(1); else
    if ~isnumeric(o.SliceZ)||~isreal(o.SliceZ)||~isscalar(o.SliceZ)||~isfinite(o.SliceZ), error('signalvis:inspectPointDelays:SliceZ','SliceZ must be finite real scalar.'); end
    [~,iz]=min(abs(uniqueZ-double(o.SliceZ)*coordFactor)); chosenZ=uniqueZ(iz);
end
if isempty(o.InitialPoint)
    initialRows=find(abs(pointsM(:,3)-chosenZ)<=zTolerance); initialPoint=initialRows(1);
else
    initialPoint=o.InitialPoint;
    if ~isnumeric(initialPoint)||~isreal(initialPoint)||~isscalar(initialPoint)||~isfinite(initialPoint)||initialPoint<1||initialPoint>size(points,1)||initialPoint~=fix(initialPoint)
        error('signalvis:inspectPointDelays:InitialPoint','InitialPoint must be a valid global point index.');
    end
    chosenZ=pointsM(initialPoint,3);
end

imageValues=[]; imageIndex=[];
if ~isempty(o.Image)
    if ~isnumeric(o.Image)||isempty(o.Image)||size(o.Image,1)~=size(points,1)
        error('signalvis:inspectPointDelays:Image','Image must be numeric with one first-dimension entry per point.');
    end
    imageValues=double(o.Image);
    ni=ndims(imageValues)-1;
    if isempty(o.ImageIndex), imageIndex=ones(1,ni);
    elseif isnumeric(o.ImageIndex)&&isreal(o.ImageIndex)&&isvector(o.ImageIndex)&&numel(o.ImageIndex)==ni, imageIndex=o.ImageIndex(:).';
    else, error('signalvis:inspectPointDelays:ImageIndex','ImageIndex must select every dimension after the point dimension.'); end
    for k=1:ni
        if imageIndex(k)<1||imageIndex(k)>size(imageValues,k+1)||imageIndex(k)~=fix(imageIndex(k)), error('signalvis:inspectPointDelays:ImageIndex','ImageIndex contains an invalid subscript.'); end
    end
    subs=[{':'},num2cell(imageIndex)]; imageValues=reshape(imageValues(subs{:}),size(points,1),1);
    invalidImage=~isfinite(real(imageValues))|~isfinite(imag(imageValues));
    comp=imageComponent;
    if strcmp(comp,'auto'), if isreal(imageValues), comp='real'; else, comp='magnitude'; end, end
    if strcmp(comp,'magnitude'), imageValues=abs(imageValues);
    elseif strcmp(comp,'real'), imageValues=real(imageValues);
    elseif strcmp(comp,'imaginary'), imageValues=imag(imageValues);
    else, error('signalvis:inspectPointDelays:ImageComponent','ImageComponent must be auto, magnitude, real or imaginary.'); end
    imageValues(invalidImage|~isfinite(imageValues))=NaN;
end

mapAxes=[]; rasterEligible=false;
if ~isempty(o.Axes)
    if ~iscell(o.Axes)||numel(o.Axes)~=3, error('signalvis:inspectPointDelays:Axes','Axes must be a three-element {xAxis,yAxis,zAxis} cell array.'); end
    mapAxes=cell(1,3);
    for k=1:3
        a=o.Axes{k};
        if ~isnumeric(a)||~isreal(a)||~isvector(a)||isempty(a)||any(~isfinite(a(:)))||any(diff(a(:))<=0)
            error('signalvis:inspectPointDelays:Axes','Each spatial axis must be a finite increasing vector.');
        end
        mapAxes{k}=double(a(:))*coordFactor;
        tolerance=axisCoverageTolerance(mapAxes{k},pointsM(:,k));
        if min(pointsM(:,k))<mapAxes{k}(1)-tolerance||max(pointsM(:,k))>mapAxes{k}(end)+tolerance
            error('signalvis:inspectPointDelays:Axes','Spatial axes must cover all supplied points.');
        end
    end
    rasterEligible=regularAxis(mapAxes{1})&&regularAxis(mapAxes{2})&&~isempty(imageValues) ...
        &&pointsMatchCentres(pointsM(:,1),mapAxes{1})&&pointsMatchCentres(pointsM(:,2),mapAxes{2});
end

channels=validateChannels(o.Channels,size(signals,2),channelsOmitted);
channelLabels=validateLabels(o.ChannelLabels,size(signals,2));
if ~isempty(o.TraceLabels), channelLabels=validateLabels(o.TraceLabels,size(signals,2)); end
quantity=lowerText(o.Quantity,'Quantity');
if strcmp(quantity,'auto'), if isreal(signals), quantity='value'; else, quantity='both'; end, end
if ~any(strcmp(quantity,{'value','magnitude','phase','both'})), error('signalvis:inspectPointDelays:Quantity','Unsupported Quantity.'); end
if strcmp(quantity,'both')&&isreal(signals), error('signalvis:inspectPointDelays:Quantity','Quantity both requires complex frequency signals.'); end
if strcmp(quantity,'phase')&&isreal(signals), error('signalvis:inspectPointDelays:Quantity','Phase cannot be derived from real time signals.'); end
if strcmp(quantity,'value')&&~isreal(signals), error('signalvis:inspectPointDelays:Quantity','Quantity value cannot discard complex frequency components.'); end
layout=lowerText(o.Layout,'Layout');
if ~any(strcmp(layout,{'overlay','individual'})), error('signalvis:inspectPointDelays:Layout','Layout must be overlay or individual.'); end
if ~isnumeric(o.ChannelsPerPage)||~isreal(o.ChannelsPerPage)||~isscalar(o.ChannelsPerPage)|| ...
        ~isfinite(o.ChannelsPerPage)||o.ChannelsPerPage<1||o.ChannelsPerPage~=fix(o.ChannelsPerPage)
    error('signalvis:inspectPointDelays:ChannelsPerPage','ChannelsPerPage must be a finite positive integer.');
end
if ~any(strcmpi(o.Legend,{'auto','on','off'})), error('signalvis:inspectPointDelays:Legend','Legend must be auto, on or off.'); end
if ~any(strcmpi(o.Visible,{'on','off'})), error('signalvis:inspectPointDelays:Visible','Visible must be on or off.'); end
if ~isnumeric(o.DBFloor)||~isreal(o.DBFloor)||~isscalar(o.DBFloor)||~isfinite(o.DBFloor), error('signalvis:inspectPointDelays:DBFloor','DBFloor must be a finite real scalar.'); end
phaseUnits=lowerText(o.PhaseUnits,'PhaseUnits');
if ~any(strcmp(phaseUnits,{'radians','degrees'})), error('signalvis:inspectPointDelays:PhaseUnits','PhaseUnits must be radians or degrees.'); end
magScale=lowerText(o.MagnitudeScale,'MagnitudeScale');
if ~any(strcmp(magScale,{'linear','db'})), error('signalvis:inspectPointDelays:MagnitudeScale','MagnitudeScale must be linear or dB.'); end
if ~(islogical(o.UnwrapPhase)&&isscalar(o.UnwrapPhase)), error('signalvis:inspectPointDelays:UnwrapPhase','UnwrapPhase must be a logical scalar.'); end

if ~isempty(o.Window)
    if ~isa(o.Window,'function_handle'), error('signalvis:inspectPointDelays:Window','Window must be a function handle.'); end
    if ~isempty(o.WindowAxis)
        wa=o.WindowAxis;
        if ~isnumeric(wa)||~isreal(wa)||~isvector(wa)||any(~isfinite(wa(:)))||any(diff(wa(:))<=0), error('signalvis:inspectPointDelays:WindowAxis','WindowAxis must be finite and increasing.'); end
    end
else
    if ~isempty(o.WindowAxis), error('signalvis:inspectPointDelays:WindowAxis','WindowAxis is only used with Window.'); end
end

cfg=struct('points',points,'pointsM',pointsM,'uniqueZ',uniqueZ,'UniqueZ',uniqueZ,'zTolerance',zTolerance, ...
    'coordFactor',coordFactor,'coordUnits',coordUnits,'displayCoordUnits',displayCoordUnits, ...
    'displayCoordFactor',coordinateFactor(displayCoordUnits),'domain',domain,'axisUnits',axisUnits, ...
    'displayAxisUnits',displayAxisUnits,'calcAxis',calcAxis(:),'dt',dt,'sampleInterval',sampleInterval,'delayUnits',delayUnits, ...
    'numericDelays',numericDelays,'imageValues',imageValues,'imageIndex',imageIndex, ...
    'mapAxes',{mapAxes},'rasterEligible',rasterEligible,'channels',channels,'channelLabels',{channelLabels}, ...
    'quantity',quantity,'layout',layout,'per',o.ChannelsPerPage,'Page',1,'initialZ',chosenZ, ...
    'window',o.Window,'pages',ceil(numel(channels)/o.ChannelsPerPage));
cfg.Pages=max(1,cfg.pages);
if isa(delays,'function_handle')
    d=evaluateDelay(delays,pointsM(initialPoint,:),size(signals,2),delayUnits,dt);
else
    d=evaluateDelay(numericDelays,pointsM(initialPoint,:),size(signals,2),delayUnits,dt,initialPoint);
end
try
    delayed=merit.process.delay(signals,d,cfg.calcAxis);
catch err
    error('signalvis:inspectPointDelays:DelayCalculation','Initial MERIT delay failed: %s',err.message);
end
compared=delayed;
comparedAxis=cfg.calcAxis;
if ~isempty(o.Window)
    compared=o.Window(delayed);
    if ~isnumeric(compared)||~ismatrix(compared)||isempty(compared)||size(compared,2)~=size(signals,2) ...
            ||(strcmp(cfg.domain,'time')&&~isreal(compared))
        error('signalvis:inspectPointDelays:WindowOutput', ...
            'Window must return a nonempty numeric samples-by-channels matrix with unchanged channel count; time output must be real.');
    end
    if size(compared,1)~=size(delayed,1)
        if isempty(o.WindowAxis)||numel(o.WindowAxis)~=size(compared,1), error('signalvis:inspectPointDelays:WindowAxis','A changed window sample count requires a matching WindowAxis.'); end
        comparedAxis=axisToSI(o.WindowAxis,axisUnits,sampleInterval);
    elseif ~isempty(o.WindowAxis)
        if numel(o.WindowAxis)~=size(compared,1), error('signalvis:inspectPointDelays:WindowAxis','WindowAxis must match the window output sample count.'); end
        comparedAxis=axisToSI(o.WindowAxis,axisUnits,sampleInterval);
    end
end
initial=makeSelection(initialPoint,chosenZ,d,signals,delayed,compared,calcAxis,comparedAxis,cfg);
end

function selection=calculateSelection(index,cfg,o,signals,points,delays)
pointM=cfg.pointsM(index,:);
if isa(delays,'function_handle')
    d=evaluateDelay(delays,pointM,size(signals,2),cfg.delayUnits,cfg.dt);
else
    d=evaluateDelay(cfg.numericDelays,pointM,size(signals,2),cfg.delayUnits,cfg.dt,index);
end
try
    delayed=merit.process.delay(signals,d,cfg.calcAxis);
catch err
    error('signalvis:inspectPointDelays:DelayCalculation','MERIT delay failed for point %d: %s',index,err.message);
end
compared=delayed;
comparedAxis=cfg.calcAxis;
if ~isempty(o.Window)
    try
        compared=o.Window(delayed);
    catch err
        error('signalvis:inspectPointDelays:WindowFailure','Window failed for point %d: %s',index,err.message);
    end
    if ~isnumeric(compared)||~ismatrix(compared)||isempty(compared)||size(compared,2)~=size(signals,2) ...
            ||(strcmp(cfg.domain,'time')&&~isreal(compared))
        error('signalvis:inspectPointDelays:WindowOutput','Window must return a nonempty numeric samples-by-channels matrix with unchanged channel count; time output must be real.');
    end
    if size(compared,1)~=size(delayed,1)
        if isempty(o.WindowAxis)||numel(o.WindowAxis)~=size(compared,1)
            error('signalvis:inspectPointDelays:WindowAxis','A changed window sample count requires a matching WindowAxis.');
        end
        comparedAxis=axisToSI(o.WindowAxis,cfg.axisUnits,o.SampleInterval);
    elseif ~isempty(o.WindowAxis)
        if numel(o.WindowAxis)~=size(compared,1), error('signalvis:inspectPointDelays:WindowAxis','WindowAxis must match the window output sample count.'); end
        comparedAxis=axisToSI(o.WindowAxis,cfg.axisUnits,o.SampleInterval);
    end
end
selection=makeSelection(index,pointM(3),d,signals,delayed,compared,cfg.calcAxis,comparedAxis,cfg);
end

function selection=makeSelection(index,sliceZ,delaysSeconds,original,delayed,compared,calcAxis,comparedAxis,cfg)
selection=struct('PointIndex',index,'Point',cfg.points(index,:), ...
    'PointMetres',cfg.pointsM(index,:),'SliceZ',sliceZ/cfg.coordFactor,'Domain',cfg.domain, ...
    'DelaysSeconds',delaysSeconds(:).','CalculationAxis',calcAxis(:), ...
    'OriginalSignals',original,'DelayedSignals',delayed,'ComparedSignals',compared, ...
    'ComparedAxis',comparedAxis(:),'Channels',cfg.channels,'Page',cfg.Page, ...
    'ImageValue',[],'CoordinateUnits',cfg.coordUnits,'DisplayCoordinateUnits',cfg.displayCoordUnits, ...
    'AxisUnits',cfg.axisUnits,'DisplayAxisUnits',cfg.displayAxisUnits,'DelayUnits',cfg.delayUnits, ...
    'SampleInterval',cfg.sampleInterval);
if ~isempty(cfg.imageValues), selection.ImageValue=cfg.imageValues(index); end
end

function text=selectionStatus(selection,cfg)
shown=selection.DelaysSeconds(cfg.channels);
shownPoint=selection.PointMetres/cfg.displayCoordFactor;
text=sprintf('Point %d: [%.5g %.5g %.5g] %s; delays (ns): %s', ...
    selection.PointIndex,shownPoint(1),shownPoint(2),shownPoint(3), ...
    cfg.displayCoordUnits,mat2str(shown*1e9,5));
end

function d=evaluateDelay(source,pointM,nChannels,units,dt,index)
if isa(source,'function_handle')
    raw=source(pointM);
    if ~isnumeric(raw)||~isreal(raw)||numel(raw)~=nChannels||any(~isfinite(raw(:)))
        error('signalvis:inspectPointDelays:DelayHandle','Delay handle must return %d finite real channel delays.',nChannels);
    end
    d=double(raw(:).');
else
    if nargin<6, error('signalvis:inspectPointDelays:DelayIndex','Numeric delays require a point index.'); end
    d=source(:,:,index);
    d=double(d(:).');
end
if strcmp(units,'ns')
    d=d*1e-9;
elseif strcmp(units,'samples')
    d=d*dt;
end
if any(~isfinite(d)), error('signalvis:inspectPointDelays:DelayValues','Delays must be finite.'); end
end

function D=normaliseDelays(input,nChannels,nPoints)
if ~isnumeric(input)||~isreal(input)||any(~isfinite(input(:)))
    error('signalvis:inspectPointDelays:DelayValues','Precomputed delays must be finite real numeric values.');
end
if nPoints==1&&isvector(input)&&numel(input)==nChannels
    D=reshape(input,1,nChannels,1);
elseif isequal(size(input),[nChannels nPoints])
    D=reshape(input,1,nChannels,nPoints);
elseif size(input,1)==1&&size(input,2)==nChannels&&size(input,3)==nPoints&&numel(input)==nChannels*nPoints
    D=reshape(input,1,nChannels,nPoints);
else
    error('signalvis:inspectPointDelays:DelayShape','Numeric delays must be 1-by-C-by-P, C-by-P, or a channel vector for one point.');
end
end

function view=viewsFor(data,cfg,o)
selected=data(:,cfg.channels);
if strcmp(cfg.domain,'frequency'), inputType='complex'; else, inputType='real'; end
[view,~]=signalvis.internal.prepareTraces(selected,inputType,cfg.quantity,'linear', ...
    lowerText(o.MagnitudeScale,'MagnitudeScale'), 'radians',lowerText(o.PhaseUnits,'PhaseUnits'), ...
    o.UnwrapPhase,o.DBFloor);
end

function view=optionalViews(data,cfg,o)
if isempty(o.Window), view={}; else, view=viewsFor(data,cfg,o); end
end

function channels=validateChannels(input,nChannels,wasOmitted)
if wasOmitted
    channels=1:nChannels;
else
    if isempty(input), error('signalvis:inspectPointDelays:Channels','An explicit empty Channels selection is invalid.'); end
    if ~isnumeric(input)||~isreal(input)||~isvector(input)
        error('signalvis:inspectPointDelays:Channels','Channels must be a numeric real vector.');
    end
    channels=input(:).';
    if any(~isfinite(channels)|channels<1|channels>nChannels|channels~=fix(channels))||numel(unique(channels))~=numel(channels)
        error('signalvis:inspectPointDelays:Channels','Channels must be unique valid positive channel indices.');
    end
end
end

function labels=validateLabels(input,nChannels)
if isempty(input)
    labels=arrayfun(@(k)sprintf('Channel %d',k),1:nChannels,'UniformOutput',false);
elseif isnumeric(input)&&isreal(input)&&isequal(size(input),[nChannels 2])
    labels=arrayfun(@(k)sprintf('(%g, %g)',input(k,1),input(k,2)),1:nChannels,'UniformOutput',false);
elseif iscell(input)
    labels=input(:).';
elseif ischar(input)||isstring(input)
    labels=cellstr(input); labels=labels(:).';
else
    error('signalvis:inspectPointDelays:ChannelLabels','Labels must be text labels or numeric C-by-2 antenna pairs.');
end
if numel(labels)~=nChannels
    error('signalvis:inspectPointDelays:ChannelLabels','Provide one label for each input channel.');
end
for k=1:numel(labels)
    if ~ischar(labels{k}), error('signalvis:inspectPointDelays:ChannelLabels','Label entries must be character vectors.'); end
end
end

function factor=unitFactor(units)
switch lower(units)
    case 's', factor=1;
    case 'ms', factor=1e-3;
    case 'us', factor=1e-6;
    case 'ns', factor=1e-9;
    case 'ps', factor=1e-12;
    case 'hz', factor=1;
    case 'khz', factor=1e3;
    case 'mhz', factor=1e6;
    case 'ghz', factor=1e9;
    otherwise, error('signalvis:inspectPointDelays:Units','Unsupported physical units: %s.',units);
end
end

function factor=coordinateFactor(units)
switch lower(units)
    case 'm', factor=1;
    case 'cm', factor=1e-2;
    case 'mm', factor=1e-3;
    otherwise, error('signalvis:inspectPointDelays:CoordinateUnits','Coordinate units must be m, cm or mm.');
end
end

function text=lowerText(value,name)
if isstring(value)&&isscalar(value), value=char(value); end
if ~ischar(value)||~isrow(value)
    error(['signalvis:inspectPointDelays:' name],'%s must be a character vector or string scalar.',name);
end
text=lower(value);
end

function tf=regularAxis(x)
if numel(x)<2, tf=false; return; end
d=diff(x);
tf=max(abs(d-mean(d)))<=max(64*eps(max(abs(d))),1e-8*abs(mean(d)));
end

function tolerance=axisCoverageTolerance(axisValues,pointValues)
scale=max([abs(axisValues(:));abs(pointValues(:));1]);
tolerance=max(64*eps(scale),1e-12*scale);
end

function tf=pointsMatchCentres(values,axisValues)
if numel(axisValues)<2
    tolerance=max(eps(max(abs(axisValues)))*64,1e-12);
else
    spacing=mean(diff(axisValues));
    tolerance=max(eps(max(abs(axisValues)))*64,abs(spacing)*1e-6);
end
for k=1:numel(values)
    if min(abs(axisValues-values(k)))>tolerance
        tf=false;
        return;
    end
end
tf=true;
end

function axisSI=axisToSI(axis,units,sampleInterval)
axis=double(axis(:));
if strcmp(units,'samples'), axisSI=axis*sampleInterval; else, axisSI=axis*unitFactor(units); end
if any(~isfinite(axisSI))||any(diff(axisSI)<=0)
    error('signalvis:inspectPointDelays:WindowAxis','Converted window coordinates must be finite and increasing.');
end
end

function handles=makeLayout(fig,cfg,o,nChannels)
handles=struct('MapAxes',[],'OriginalAxes',[],'DelayedAxes',[],'WindowedAxes',[], ...
    'SliceControl',[],'PreviousPage',[],'NextPage',[],'PageText',[],'Status',[]);
if isempty(o.Window), plotStart=.34; plotWidth=.63; else, plotStart=.29; plotWidth=.68; end
handles.MapAxes=axes('Parent',fig,'Units','normalized','Position',[.035 .2 .24 .72]);
title(handles.MapAxes,'Select a point','Interpreter','none');
if numel(cfg.uniqueZ)>1
    zdisplay=cfg.uniqueZ/cfg.displayCoordFactor;
    strings=arrayfun(@(z)sprintf('z = %.6g %s',z,cfg.displayCoordUnits),zdisplay,'UniformOutput',false);
    [~,zIndex]=min(abs(cfg.uniqueZ-cfg.initialZ));
    handles.SliceControl=uicontrol(fig,'Style','popupmenu','String',strings,'Value',zIndex, ...
        'Units','normalized','Position',[.04 .13 .23 .045]);
end
handles.Status=uicontrol(fig,'Style','text','String','Ready','HorizontalAlignment','left', ...
    'Units','normalized','Position',[.035 .07 .6 .04]);
nQuantity=1+strcmp(cfg.quantity,'both');
if strcmp(cfg.layout,'overlay'), nRows=nQuantity; nColumns=1;
else, nRows=min(nChannels,cfg.per); nColumns=nQuantity; end
% The gap between panels leaves room for the next panel's y tick labels and y label.
panelGap=.045;
if isempty(o.Window)
    panelW=(plotWidth-panelGap)/2;
    handles.OriginalAxes=createPanelAxes(fig,plotStart,panelW,nRows,nColumns);
    handles.DelayedAxes=createPanelAxes(fig,plotStart+panelW+panelGap,panelW,nRows,nColumns);
else
    panelW=(plotWidth-2*panelGap)/3;
    handles.OriginalAxes=createPanelAxes(fig,plotStart,panelW,nRows,nColumns);
    handles.DelayedAxes=createPanelAxes(fig,plotStart+panelW+panelGap,panelW,nRows,nColumns);
    handles.WindowedAxes=createPanelAxes(fig,plotStart+2*(panelW+panelGap),panelW,nRows,nColumns);
end
if strcmp(cfg.layout,'individual')&&cfg.Pages>1
    handles.PreviousPage=uicontrol(fig,'Style','pushbutton','String','Previous','Enable','off', ...
        'Units','normalized','Position',[.73 .025 .1 .04]);
    handles.NextPage=uicontrol(fig,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[.84 .025 .1 .04]);
    handles.PageText=uicontrol(fig,'Style','text','String',sprintf('Page 1 of %d',cfg.Pages), ...
        'Units','normalized','Position',[.61 .025 .11 .04]);
end
end

function ax=createPanelAxes(fig,x,width,nRows,nColumns)
ax=gobjects(nRows*nColumns,1);
for row=1:nRows
    for col=1:nColumns
        idx=(row-1)*nColumns+col;
        % Gaps leave room for tick labels, the x label and the title of the row below.
        gapX=.04; gapY=.075;
        cellW=(width-gapX*(nColumns-1))/nColumns;
        cellH=(.70-gapY*(nRows-1))/nRows;
        left=x+(col-1)*(cellW+gapX);
        bottom=.20+(nRows-row)*(cellH+gapY);
        ax(idx)=axes('Parent',fig,'Units','normalized','Position',[left bottom cellW cellH]);
    end
end
end

function renderComparison(ax,data,axisSI,cfg,o,page,panelName)
if isempty(data), return; end
qnames=cell(1,numel(data));
for q=1:numel(data)
    qnames{q}=quantityLabel(cfg,o,q);
end
panelOptions=o;
panelOptions.Title=panelName;
if ~isempty(o.Title), panelOptions.Title=[char(o.Title) ' - ' panelName]; end
panelOptions.XLabel=axisLabel(cfg);
panelOptions.YLabel=qnames;
fig=ancestor(ax(1),'figure');
setappdata(fig,'signalvisPage',page);
signalvis.internal.renderChannels(ax,data,displayAxis(axisSI,cfg), ...
    cfg.channelLabels(cfg.channels),qnames,cfg.layout,panelOptions,axisLabel(cfg),numel(axisSI));
end

function label=quantityLabel(cfg,o,q)
scale=lowerText(o.MagnitudeScale,'MagnitudeScale');
if strcmp(scale,'db'), scale='dB'; end
if strcmp(cfg.quantity,'value')
    label='Value';
elseif strcmp(cfg.quantity,'magnitude')
    label=['Magnitude (' scale ')'];
elseif strcmp(cfg.quantity,'phase')
    label=['Phase (' lowerText(o.PhaseUnits,'PhaseUnits') ')'];
elseif q==1
    label=['Magnitude (' scale ')'];
else
    label=['Phase (' lowerText(o.PhaseUnits,'PhaseUnits') ')'];
end
end

function label=axisLabel(cfg)
if strcmp(cfg.axisUnits,'samples')
    label='Samples';
else
    units=cfg.displayAxisUnits;
    unitNames={'s','ms','us','ns','ps','Hz','kHz','MHz','GHz'};
    lowerNames=cellfun(@lower,unitNames,'UniformOutput',false);
    match=find(strcmp(lowerNames,units),1);
    if ~isempty(match), units=unitNames{match}; end
    label=[upper(cfg.domain(1)) cfg.domain(2:end) ' (' units ')'];
end
end

function x=displayAxis(axisSI,cfg)
if strcmp(cfg.axisUnits,'samples')
    x=axisSI/cfg.sampleInterval;
else
    x=axisSI/unitFactor(cfg.displayAxisUnits);
end
end

function renderPointMap(ax,cfg,index,o)
cla(ax);
hold(ax,'on');
onPlane=abs(cfg.pointsM(:,3)-cfg.pointsM(index,3))<=cfg.zTolerance;
x=cfg.pointsM(:,1)/cfg.displayCoordFactor;
y=cfg.pointsM(:,2)/cfg.displayCoordFactor;
if cfg.rasterEligible
    xAxis=cfg.mapAxes{1}/cfg.displayCoordFactor;
    yAxis=cfg.mapAxes{2}/cfg.displayCoordFactor;
    selectedRows=find(onPlane);
    raster=nan(numel(yAxis),numel(xAxis));
    for k=selectedRows(:).'
        [~,ix]=min(abs(cfg.mapAxes{1}-cfg.pointsM(k,1)));
        [~,iy]=min(abs(cfg.mapAxes{2}-cfg.pointsM(k,2)));
        raster(iy,ix)=cfg.imageValues(k);
    end
    h=imagesc(ax,xAxis,yAxis,raster);
    set(h,'AlphaData',isfinite(raster),'HitTest','off');
    set(ax,'YDir','normal'); colorbar(ax);
    pointsHandle=plot(ax,x(onPlane),y(onPlane),'.','Color',[.15 .15 .15],'MarkerSize',7);
    set(pointsHandle,'HitTest','off');
elseif ~isempty(cfg.imageValues)
    if any(isfinite(cfg.imageValues(onPlane)))
        h=scatter(ax,x(onPlane),y(onPlane),24,cfg.imageValues(onPlane),'filled');
    else
        h=plot(ax,x(onPlane),y(onPlane),'.','Color',[.15 .35 .65],'MarkerSize',10);
    end
    set(h,'HitTest','off');
else
    h=plot(ax,x(onPlane),y(onPlane),'.','Color',[.15 .35 .65],'MarkerSize',10);
    set(h,'HitTest','off');
end
marker=plot(ax,x(index),y(index),'ro','MarkerSize',10,'LineWidth',2);
set(marker,'HitTest','off');
hold(ax,'off'); axis(ax,'equal'); grid(ax,'on');
xlabel(ax,['x (' cfg.displayCoordUnits ')'],'Interpreter','none');
ylabel(ax,['y (' cfg.displayCoordUnits ')'],'Interpreter','none');
shownPoint=cfg.pointsM(index,:)/cfg.displayCoordFactor;
title(ax,sprintf('Point %d: [%.5g %.5g %.5g] %s',index, ...
    shownPoint(1),shownPoint(2),shownPoint(3),cfg.displayCoordUnits),'Interpreter','none');
end
