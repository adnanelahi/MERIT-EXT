function [fig, viewer] = signalViewer(signals, sampleAxis, channelPairs, varargin)
%SIGNALVIEWER Choose interactively which channel signals to display and compare.
%   [FIG, VIEWER] = signalvis.signalViewer(SIGNALS, AXIS, CHANNELPAIRS, Name,Value,...)
%   SIGNALS is a samples-by-C array, or a cell array of such arrays with the
%   same size (datasets to compare, such as original, rotated and
%   rotation-subtracted scans). AXIS has one value per sample, or is empty
%   for sample numbers. CHANNELPAIRS is MERIT's C-by-2 channel_names array
%   (Tx, Rx), or empty.
%   In the figure, tick Tx and Rx antennas to show the channels whose Tx and
%   Rx are both ticked; tick or untick single channels in the channel list;
%   with References, choose a channel to show it with its reference
%   channels; with several datasets, tick datasets.
%   Options:
%     InputType            auto, complex, waveform, magnitude or phase; a
%                          cell array gives one type per dataset. Real data
%                          is a waveform unless declared otherwise.
%     InputMagnitudeScale  linear or dB (per dataset in a cell array)
%     InputPhaseUnits      radians or degrees (per dataset in a cell array)
%     DatasetNames         one name per dataset
%     AxisUnits            samples, Hz, kHz, MHz, GHz, s, ms, us, ns or ps
%     DisplayAxisUnits     display units in the same family
%     References           reference channels of each channel: the cell
%                          array from artefact.referenceChannels, or the
%                          structure from neighbourhoodEditor's GetResult
%     InitialTx, InitialRx antennas ticked at the start (default all)
%     Quantity             magnitude, phase, both, value, real or imaginary
%     MagnitudeScale       linear or dB
%     PhaseUnits           radians or degrees
%     UnwrapPhase          true or false
%     Layout               overlay or individual
%     ChannelsPerPage      panels per page in the individual layout (6)
%     Title, Visible
%   VIEWER provides SelectTx, SelectRx, SelectChannels, ShowReference,
%   SelectDatasets, SetDisplay, GetSelection and GetDisplayedData.
%   Example:
%     signalvis.signalViewer({scan1, scan2, scan1-scan2}, frequencies, channel_names, ...
%         'DatasetNames', {'Original','Rotated','Subtracted'}, ...
%         'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz');

if nargin<1
    error('signalvis:signalViewer:NotEnoughInputs','Signals are required.');
end
if nargin<2, sampleAxis=[]; end
if nargin<3, channelPairs=[]; end
if iscell(signals), signals=signals(:).'; else, signals={signals}; end
D=numel(signals);
if D==0
    error('signalvis:signalViewer:Signals','Signals must contain at least one array.');
end
for d=1:D
    s=signals{d};
    if ~(isnumeric(s)&&(isa(s,'single')||isa(s,'double'))&&ismatrix(s)&&~isempty(s))
        error('signalvis:signalViewer:Signals','Each signal array must be a nonempty single or double samples-by-channels matrix.');
    end
    if ~isequal(size(s),size(signals{1}))
        error('signalvis:signalViewer:Signals','All signal arrays must have the same number of samples and channels.');
    end
end
[N,C]=size(signals{1});
if ~isempty(sampleAxis)&&~(isnumeric(sampleAxis)&&isreal(sampleAxis)&&isvector(sampleAxis)&&numel(sampleAxis)==N&&all(isfinite(sampleAxis(:))))
    error('signalvis:signalViewer:SampleAxis','The sample axis must be empty or a finite real vector with one value per sample.');
end
hasPairs=~isempty(channelPairs);
if hasPairs
    if ~(isnumeric(channelPairs)&&isreal(channelPairs)&&isequal(size(channelPairs),[C 2]) ...
            &&all(channelPairs(:)==round(channelPairs(:)))&&all(channelPairs(:)>=1))
        error('signalvis:signalViewer:ChannelPairs','Channel pairs must be empty or a C-by-2 array of positive antenna numbers, one row per signal column.');
    end
    channelPairs=double(channelPairs);
end

p=inputParser; p.FunctionName='signalvis.signalViewer';
addParameter(p,'InputType','auto'); addParameter(p,'InputMagnitudeScale','linear'); addParameter(p,'InputPhaseUnits','radians');
addParameter(p,'DatasetNames',{}); addParameter(p,'AxisUnits',''); addParameter(p,'DisplayAxisUnits','');
addParameter(p,'References',[]); addParameter(p,'InitialTx',[]); addParameter(p,'InitialRx',[]);
addParameter(p,'Quantity',''); addParameter(p,'MagnitudeScale',''); addParameter(p,'PhaseUnits','');
addParameter(p,'UnwrapPhase',false); addParameter(p,'Layout','overlay'); addParameter(p,'ChannelsPerPage',6);
addParameter(p,'Title',''); addParameter(p,'Visible','on');
parse(p,varargin{:}); o=p.Results;

types=perDataset(o.InputType,'InputType',{'auto','complex','waveform','magnitude','phase'});
inMagScale=perDataset(o.InputMagnitudeScale,'InputMagnitudeScale',{'linear','db'});
inPhaseUnits=perDataset(o.InputPhaseUnits,'InputPhaseUnits',{'radians','degrees'});
for d=1:D
    if strcmp(types{d},'auto')
        if isreal(signals{d}), types{d}='waveform'; else, types{d}='complex'; end
    end
    if ~strcmp(types{d},'complex')&&~isreal(signals{d})
        error('signalvis:signalViewer:InputType','InputType %s requires real values (dataset %d).',types{d},d);
    end
    if strcmp(types{d},'magnitude')&&strcmp(inMagScale{d},'linear')&&any(signals{d}(isfinite(signals{d}))<0)
        error('signalvis:signalViewer:InputMagnitudeScale','Linear magnitudes must be nonnegative (dataset %d); declare dB input with InputMagnitudeScale.',d);
    end
end
if isempty(o.DatasetNames)
    if D==1, names={'Signals'}; else, names=arrayfun(@(d)sprintf('Dataset %d',d),1:D,'UniformOutput',false); end
else
    names=o.DatasetNames;
    if ischar(names)||isstring(names), names=cellstr(names); end
    if ~(iscellstr(names)&&numel(names)==D)
        error('signalvis:signalViewer:DatasetNames','DatasetNames must contain one name per dataset.');
    end
    names=names(:).';
end

if isempty(sampleAxis)
    xSI=(1:N).';
    if isempty(o.AxisUnits), axisUnits='samples'; else, axisUnits=unitKey(o.AxisUnits,'AxisUnits'); end
else
    xSI=double(sampleAxis(:));
    axisUnits=unitKey(o.AxisUnits,'AxisUnits');
end
if isempty(o.DisplayAxisUnits), displayUnits=axisUnits; else, displayUnits=unitKey(o.DisplayAxisUnits,'DisplayAxisUnits'); end
[xDisplay,axisLabel]=displayAxis(xSI,axisUnits,displayUnits);

if hasPairs
    tx=channelPairs(:,1).'; rx=channelPairs(:,2).';
    txAntennas=unique(tx); rxAntennas=unique(rx);
    channelLabels=arrayfun(@(c)sprintf('%d-%d',tx(c),rx(c)),1:C,'UniformOutput',false);
else
    tx=nan(1,C); rx=nan(1,C); txAntennas=[]; rxAntennas=[];
    channelLabels=arrayfun(@(c)sprintf('Channel %d',c),1:C,'UniformOutput',false);
end
hasReferences=~isempty(o.References);
referenceSets={};
if hasReferences
    refs=o.References;
    if isstruct(refs)&&isfield(refs,'References'), refs=refs.References; end
    if ~(iscell(refs)&&numel(refs)==C)
        error('signalvis:signalViewer:References','References must list the reference channels of each of the %d channels.',C);
    end
    for c=1:C
        r=refs{c};
        if ~(isempty(r)||(isnumeric(r)&&isreal(r)&&isvector(r)&&all(r==round(r))&&all(r>=1)&&all(r<=C)))
            error('signalvis:signalViewer:References','Reference channels of channel %d must be channel numbers from 1 to %d.',c,C);
        end
    end
    referenceSets=cellfun(@(r)unique(double(r(:)).'),refs(:).','UniformOutput',false);
end
focusChannel=0;

txTick=true(1,numel(txAntennas)); rxTick=true(1,numel(rxAntennas));
if ~isempty(o.InitialTx), txTick=ismember(txAntennas,antennaSubset(o.InitialTx,txAntennas,'InitialTx')); end
if ~isempty(o.InitialRx), rxTick=ismember(rxAntennas,antennaSubset(o.InitialRx,rxAntennas,'InitialRx')); end
if hasPairs, chanSel=matchTxRx(); else, chanSel=true(1,C); end
dataSel=true(1,D);

available=quantityKeysAll(); available=available(ismember(available,availableQuantities(types)));
opts=struct('Quantity',defaultQuantity(types{1}),'MagnitudeScale','linear','PhaseUnits','radians', ...
    'UnwrapPhase',false,'Layout','overlay','ChannelsPerPage',6,'Page',1);
if strcmp(types{1},'magnitude'), opts.MagnitudeScale=inMagScale{1}; end
if strcmp(types{1},'phase'), opts.PhaseUnits=inPhaseUnits{1}; end
requested={};
for name={'Quantity','MagnitudeScale','PhaseUnits','UnwrapPhase','Layout','ChannelsPerPage'}
    if ~any(strcmp(name{1},p.UsingDefaults))
        requested=[requested {name{1},o.(name{1})}]; %#ok<AGROW>
    end
end
opts=validateDisplay(opts,requested);
titleText=textOption(o.Title,'Title');
visible=lower(textOption(o.Visible,'Visible'));
if ~any(strcmp(visible,{'on','off'}))
    error('signalvis:signalViewer:Visible','Visible must be on or off.');
end
lineData(); % Validate the first display before creating graphics.

% ---- Figure ----
fig=figure('Visible',visible,'Name','Signal viewer','NumberTitle','off','Units','normalized', ...
    'Position',[.04 .06 .92 .86]);
plotPanel=uipanel(fig,'Units','normalized','Position',[.24 .1 .55 .8],'BorderType','none');
quantityKeys={'magnitude','phase','both','value','real','imaginary'};
quantityNames={'Magnitude','Phase','Magnitude and phase','Value','Real part','Imaginary part'};
offered=quantityKeys(ismember(quantityKeys,available));
offeredNames=quantityNames(ismember(quantityKeys,available));
label(fig,'Quantity',[.24 .955 .14 .025]);
quantityPopup=uicontrol(fig,'Style','popupmenu','String',offeredNames,'Units','normalized', ...
    'Position',[.24 .925 .14 .03],'Callback',@onDisplay);
label(fig,'Magnitude scale',[.39 .955 .09 .025]);
scalePopup=uicontrol(fig,'Style','popupmenu','String',{'linear','dB'},'Units','normalized', ...
    'Position',[.39 .925 .09 .03],'Callback',@onDisplay);
label(fig,'Phase units',[.49 .955 .09 .025]);
phasePopup=uicontrol(fig,'Style','popupmenu','String',{'radians','degrees'},'Units','normalized', ...
    'Position',[.49 .925 .09 .03],'Callback',@onDisplay);
unwrapCheck=uicontrol(fig,'Style','checkbox','String','Unwrap phase','Units','normalized', ...
    'Position',[.59 .925 .09 .03],'Callback',@onDisplay);
label(fig,'Layout',[.69 .955 .1 .025]);
layoutPopup=uicontrol(fig,'Style','popupmenu','String',{'overlay','individual'},'Units','normalized', ...
    'Position',[.69 .925 .1 .03],'Callback',@onDisplay);
statusText=uicontrol(fig,'Style','text','String','','Units','normalized','Position',[.24 .01 .33 .05], ...
    'HorizontalAlignment','left');
previousButton=uicontrol(fig,'Style','pushbutton','String','Previous','Units','normalized', ...
    'Position',[.6 .02 .055 .04],'Callback',@(~,~)uiAction(@()turnPage(-1)));
pageText=uicontrol(fig,'Style','text','String','','Units','normalized','Position',[.66 .02 .07 .03]);
nextButton=uicontrol(fig,'Style','pushbutton','String','Next','Units','normalized', ...
    'Position',[.735 .02 .055 .04],'Callback',@(~,~)uiAction(@()turnPage(1)));

txTable=gobjects(0); rxTable=gobjects(0); datasetTable=gobjects(0); referencePopup=gobjects(0); referenceText=gobjects(0);
if hasPairs
    label(fig,'Tx antennas',[.01 .955 .105 .025]);
    txTable=checkTable(fig,{'Tx','Show'},[.01 .56 .105 .395],@onTxEdit);
    tableButtons(fig,[.01 .515 .105 .037],@()SelectTx(txAntennas),@()SelectTx([]));
    label(fig,'Rx antennas',[.12 .955 .105 .025]);
    rxTable=checkTable(fig,{'Rx','Show'},[.12 .56 .105 .395],@onRxEdit);
    tableButtons(fig,[.12 .515 .105 .037],@()SelectRx(rxAntennas),@()SelectRx([]));
end
if hasReferences
    label(fig,'Channel and its reference channels',[.01 .475 .215 .025]);
    referencePopup=uicontrol(fig,'Style','popupmenu','String',[{'(none)'} channelLabels], ...
        'Units','normalized','Position',[.01 .44 .215 .03],'Callback',@onReferencePopup);
    referenceText=uicontrol(fig,'Style','text','String','','Units','normalized', ...
        'Position',[.01 .27 .215 .16],'HorizontalAlignment','left');
end
if D>1
    label(fig,'Datasets',[.01 .215 .215 .025]);
    datasetTable=checkTable(fig,{'Dataset','Line','Show'},[.01 .06 .215 .155],@onDatasetEdit);
end
label(fig,'Channels (ticked channels are shown)',[.8 .955 .19 .025]);
channelTable=checkTable(fig,{'Channel','Show'},[.8 .13 .19 .825],@onChannelEdit);
tableButtons(fig,[.8 .085 .19 .037],@()SelectChannels(1:C),@()SelectChannels([]));
countText=uicontrol(fig,'Style','text','String','','Units','normalized','Position',[.8 .02 .19 .05], ...
    'HorizontalAlignment','left');

viewer=struct('Figure',fig,'PlotPanel',plotPanel,'TxTable',txTable,'RxTable',rxTable, ...
    'ChannelTable',channelTable,'ReferencePopup',referencePopup,'DatasetTable',datasetTable, ...
    'QuantityPopup',quantityPopup,'Status',statusText, ...
    'SelectTx',@SelectTx,'SelectRx',@SelectRx,'SelectChannels',@SelectChannels, ...
    'ShowReference',@ShowReference,'SelectDatasets',@SelectDatasets,'SetDisplay',@SetDisplay, ...
    'GetSelection',@GetSelection,'GetDisplayedData',@GetDisplayedData);
refreshTables({'tx','rx','channels','reference','datasets'});
% Column widths follow the table widths when the window is resized.
tableColumns={txTable,[.55 .45];rxTable,[.55 .45];datasetTable,[.45 .3 .25];channelTable,[.6 .4]};
set(fig,'SizeChangedFcn',@(~,~)fitColumns(tableColumns));
fitColumns(tableColumns);
refreshControls();
redraw('Tick antennas or channels to choose the signals shown.');

% ---- Programmatic interface ----
    function SelectTx(antennas)
        requirePairs();
        txTick=ismember(txAntennas,antennaSubset(antennas,txAntennas,'Tx'));
        chanSel=matchTxRx(); focusChannel=0;
        opts.Page=1;
        refreshTables({'tx','channels','reference'});
        redraw(sprintf('Tx antennas: %s.',listText(txAntennas(txTick))));
    end

    function SelectRx(antennas)
        requirePairs();
        rxTick=ismember(rxAntennas,antennaSubset(antennas,rxAntennas,'Rx'));
        chanSel=matchTxRx(); focusChannel=0;
        opts.Page=1;
        refreshTables({'rx','channels','reference'});
        redraw(sprintf('Rx antennas: %s.',listText(rxAntennas(rxTick))));
    end

    function SelectChannels(indices)
        indices=indexList(indices,C,'Channels');
        chanSel=false(1,C); chanSel(indices)=true; focusChannel=0;
        opts.Page=1;
        refreshTables({'channels','reference'});
        redraw(sprintf('%d channels selected.',nnz(chanSel)));
    end

    function ShowReference(channel)
        % Show a channel, drawn with a thicker line, and its reference
        % channels; 0 or [] clears the choice.
        if ~hasReferences
            error('signalvis:signalViewer:References','No reference channels were supplied.');
        end
        if isempty(channel)||isequal(channel,0)
            focusChannel=0;
            refreshTables({'reference'});
            redraw('No channel chosen for its reference.');
            return;
        end
        if ~(isnumeric(channel)&&isscalar(channel)&&channel==round(channel)&&channel>=1&&channel<=C)
            error('signalvis:signalViewer:Channel','Channel must be a number between 1 and %d.',C);
        end
        focusChannel=double(channel);
        chanSel=false(1,C); chanSel([focusChannel referenceSets{focusChannel}])=true;
        if hasPairs
            txTick=ismember(txAntennas,tx(chanSel)); rxTick=ismember(rxAntennas,rx(chanSel));
        end
        opts.Page=1;
        refreshTables({'tx','rx','channels','reference'});
        redraw(sprintf('Channel %s (thick line) with its reference channels: %s.',channelLabels{focusChannel}, ...
            labelsText(referenceSets{focusChannel})));
    end

    function SelectDatasets(indices)
        indices=indexList(indices,D,'Datasets');
        dataSel=false(1,D); dataSel(indices)=true;
        refreshTables({'datasets'});
        redraw(sprintf('%d of %d datasets shown.',nnz(dataSel),D));
    end

    function SetDisplay(varargin)
        if mod(numel(varargin),2)~=0
            error('signalvis:signalViewer:SetDisplay','Display options must be name-value pairs.');
        end
        updated=validateDisplay(opts,varargin);
        previous=opts; opts=updated;
        try
            lineData();
        catch problem
            opts=previous; rethrow(problem);
        end
        refreshControls();
        redraw('Display updated.');
    end

    function selection=GetSelection()
        selection=struct('Tx',txAntennas(txTick),'Rx',rxAntennas(rxTick),'Channels',find(chanSel), ...
            'ChannelLabels',{channelLabels(chanSel)},'ReferenceFor',focusChannel,'Datasets',find(dataSel), ...
            'DatasetNames',{names(dataSel)},'Quantity',opts.Quantity,'MagnitudeScale',opts.MagnitudeScale, ...
            'PhaseUnits',opts.PhaseUnits,'UnwrapPhase',opts.UnwrapPhase,'Layout',opts.Layout, ...
            'Page',opts.Page,'Pages',pageCount());
    end

    function lines=GetDisplayedData()
        lines=lineData();
    end

% ---- Data for display ----
    function lines=lineData()
        % Values of every displayed line; the individual layout shows one page.
        quantities=axisQuantities(opts.Quantity);
        channels=find(chanSel);
        if strcmp(opts.Layout,'individual')
            first=(opts.Page-1)*opts.ChannelsPerPage+1;
            channels=channels(first:min(numel(channels),first+opts.ChannelsPerPage-1));
        end
        lines=struct('Quantity',{},'QuantityLabel',{},'Dataset',{},'DatasetName',{},'Channel',{}, ...
            'Tx',{},'Rx',{},'Label',{},'Highlighted',{},'X',{},'Y',{});
        for q=1:numel(quantities)
            for d=find(dataSel)
                if ~supports(types{d},quantities{q}) || isempty(channels), continue; end
                Y=convert(signals{d}(:,channels),d,quantities{q});
                for k=1:numel(channels)
                    c=channels(k);
                    lineLabel=channelLabels{c};
                    if D>1, lineLabel=[lineLabel ' (' names{d} ')']; end %#ok<AGROW>
                    lines(end+1)=struct('Quantity',quantities{q},'QuantityLabel',quantityLabel(quantities{q}), ...
                        'Dataset',d,'DatasetName',names{d},'Channel',c,'Tx',tx(c),'Rx',rx(c), ...
                        'Label',lineLabel,'Highlighted',c==focusChannel,'X',xDisplay,'Y',Y(:,k)); %#ok<AGROW>
                end
            end
        end
    end

    function Y=convert(A,d,quantity)
        switch quantity
            case {'magnitude','phase'}
                kinds=struct('complex','complex','waveform','real','magnitude','magnitude','phase','phase');
                data=signalvis.internal.prepareTraces(A,kinds.(types{d}),quantity,inMagScale{d}, ...
                    opts.MagnitudeScale,inPhaseUnits{d},opts.PhaseUnits,opts.UnwrapPhase,-Inf);
                Y=data{1};
            case 'value', Y=double(A);
            case 'real', Y=real(double(A));
            case 'imaginary', Y=imag(double(A));
        end
    end

    function out=quantityLabel(quantity)
        switch quantity
            case 'magnitude'
                if strcmp(opts.MagnitudeScale,'db'), out='Magnitude (dB)'; else, out='Magnitude (linear)'; end
            case 'phase', out=['Phase (' opts.PhaseUnits ')'];
            case 'value', out='Value';
            case 'real', out='Real part';
            case 'imaginary', out='Imaginary part';
        end
    end

    function n=pageCount()
        n=max(1,ceil(nnz(chanSel)/opts.ChannelsPerPage));
    end

    function selected=matchTxRx()
        selected=ismember(tx,txAntennas(txTick))&ismember(rx,rxAntennas(rxTick));
    end

    function requirePairs()
        if ~hasPairs
            error('signalvis:signalViewer:ChannelPairs','Tx and Rx selection requires channel pairs.');
        end
    end

    function updated=validateDisplay(current,args)
        updated=current;
        for k=1:2:numel(args)
            name=args{k};
            if ~(ischar(name)||(isstring(name)&&isscalar(name)))
                error('signalvis:signalViewer:SetDisplay','Display option names must be text.');
            end
            value=args{k+1};
            switch lower(char(name))
                case 'quantity'
                    value=choice(value,'Quantity',quantityKeysAll());
                    if ~any(strcmp(value,available))
                        error('signalvis:signalViewer:Quantity','Quantity %s is not available for the supplied input types (available: %s).',value,strjoin(available,', '));
                    end
                    updated.Quantity=value;
                case 'magnitudescale', updated.MagnitudeScale=choice(value,'MagnitudeScale',{'linear','db'});
                case 'phaseunits', updated.PhaseUnits=choice(value,'PhaseUnits',{'radians','degrees'});
                case 'unwrapphase'
                    if ~((islogical(value)||isnumeric(value))&&isscalar(value)&&any(value==[0 1]))
                        error('signalvis:signalViewer:UnwrapPhase','UnwrapPhase must be true or false.');
                    end
                    updated.UnwrapPhase=logical(value);
                case 'layout', updated.Layout=choice(value,'Layout',{'overlay','individual'});
                case 'channelsperpage'
                    if ~(isnumeric(value)&&isscalar(value)&&isreal(value)&&value>=1&&value==round(value))
                        error('signalvis:signalViewer:ChannelsPerPage','ChannelsPerPage must be a positive integer.');
                    end
                    updated.ChannelsPerPage=double(value);
                case 'page'
                    if ~(isnumeric(value)&&isscalar(value)&&value==round(value)&&value>=1)
                        error('signalvis:signalViewer:Page','Page must be a positive integer.');
                    end
                    updated.Page=double(value);
                otherwise
                    error('signalvis:signalViewer:SetDisplay','Unknown display option %s.',char(name));
            end
        end
        maxPage=max(1,ceil(nnz(chanSel)/updated.ChannelsPerPage));
        if updated.Page>maxPage
            error('signalvis:signalViewer:Page','Page must not exceed %d.',maxPage);
        end
    end

% ---- Graphics ----
    function redraw(message)
        if ~isgraphics(fig), return; end
        opts.Page=min(opts.Page,pageCount());
        delete(get(plotPanel,'Children'));
        lines=lineData();
        quantities=axisQuantities(opts.Quantity);
        channels=find(chanSel);
        if strcmp(opts.Layout,'overlay')
            nQ=numel(quantities);
            colours=lineColours(numel(channels));
            styles={'-','--',':','-.'};
            for q=1:nQ
                ax=axes('Parent',plotPanel,'Units','normalized', ...
                    'Position',[.09 .08+(nQ-q)*(.9/nQ) .88 .9/nQ-.1]);
                hold(ax,'on'); grid(ax,'on');
                inAxis=lines(strcmp({lines.Quantity},quantities{q}));
                for k=1:numel(inAxis)
                    rank=find(channels==inAxis(k).Channel,1);
                    drawLine(ax,inAxis(k),colours(rank,:),styles{mod(inAxis(k).Dataset-1,4)+1});
                end
                finishAxes(ax,quantityLabel(quantities{q}),numel(inAxis),q==1);
            end
        else
            first=(opts.Page-1)*opts.ChannelsPerPage+1;
            pageChannels=channels(first:min(numel(channels),first+opts.ChannelsPerPage-1));
            nRows=max(1,numel(pageChannels)); nQ=numel(quantities);
            colours=lineColours(D);
            styles={'-','--',':','-.'};
            % Quantity names head the columns, channel names sit inside each
            % panel, and only the bottom row carries x tick labels, so that
            % short panels on small screens keep their labels apart.
            left=.07; colGap=.06; top=.86; bottom=.08; rowGap=.015;
            cellW=(.98-left-(nQ-1)*colGap)/nQ; cellH=(top-bottom)/nRows;
            legendAxes=[];
            for r=1:numel(pageChannels)
                for q=1:nQ
                    ax=axes('Parent',plotPanel,'Units','normalized', ...
                        'Position',[left+(q-1)*(cellW+colGap) bottom+(nRows-r)*cellH cellW cellH-rowGap]);
                    hold(ax,'on'); grid(ax,'on');
                    inAxis=lines(strcmp({lines.Quantity},quantities{q})&[lines.Channel]==pageChannels(r));
                    for k=1:numel(inAxis)
                        inAxis(k).Label=inAxis(k).DatasetName;
                        drawLine(ax,inAxis(k),colours(inAxis(k).Dataset,:),styles{mod(inAxis(k).Dataset-1,4)+1});
                    end
                    text(ax,.01,.97,channelLabels{pageChannels(r)},'Units','normalized','Interpreter','none', ...
                        'VerticalAlignment','top','FontWeight','bold','BackgroundColor','w','Margin',1);
                    if r==1, title(ax,quantityLabel(quantities{q}),'Interpreter','none'); end
                    if r==numel(pageChannels)
                        xlabel(ax,axisLabel,'Interpreter','none');
                    else
                        set(ax,'XTickLabel',{});
                    end
                    if D>1&&isempty(legendAxes)&&~isempty(inAxis), legendAxes=ax; end
                end
            end
            if ~isempty(legendAxes)
                lg=legend(legendAxes,'show');
                set(lg,'Interpreter','none','Orientation','horizontal','Units','normalized');
                position=get(lg,'Position');
                set(lg,'Position',[.5-position(3)/2 .985-position(4) position(3) position(4)]);
            end
            if isempty(pageChannels), emptyAxes(); end
        end
        pages=pageCount();
        showPaging=strcmp(opts.Layout,'individual')&&pages>1;
        set([previousButton nextButton pageText],'Visible',onOff(showPaging));
        set(pageText,'String',sprintf('Page %d of %d',opts.Page,pages));
        set(previousButton,'Enable',onOff(opts.Page>1));
        set(nextButton,'Enable',onOff(opts.Page<pages));
        set(countText,'String',sprintf('%d of %d channels and %d of %d datasets shown.', ...
            nnz(chanSel),C,nnz(dataSel),D));
        missing=names(dataSel&~cellfun(@(t)any(cellfun(@(q)supports(t,q),quantities)),types));
        if ~isempty(missing)
            message=sprintf('%s Not shown for this quantity: %s.',message,strjoin(missing,', '));
        end
        set(statusText,'String',message);
    end

    function drawLine(ax,line,colour,style)
        if N==1, marker='o'; else, marker='none'; end
        if line.Highlighted, width=2.5; else, width=0.5; end
        plot(ax,line.X,line.Y,'Color',colour,'LineStyle',style,'Marker',marker,'LineWidth',width,'DisplayName',line.Label);
    end

    function finishAxes(ax,yLabel,count,isTop)
        ylabel(ax,yLabel,'Interpreter','none'); xlabel(ax,axisLabel,'Interpreter','none');
        if isTop
            if isempty(titleText), title(ax,'Selected signals','Interpreter','none');
            else, title(ax,titleText,'Interpreter','none'); end
        end
        if count==0
            text(ax,.5,.5,'No signals selected for this quantity','Units','normalized', ...
                'HorizontalAlignment','center','Color',[.4 .4 .4]);
        elseif count<=12
            lg=legend(ax,'show'); set(lg,'Interpreter','none','Location','best');
        end
    end

    function emptyAxes()
        ax=axes('Parent',plotPanel,'Units','normalized','Position',[.09 .08 .88 .82]);
        text(ax,.5,.5,'No channels selected','Units','normalized','HorizontalAlignment','center','Color',[.4 .4 .4]);
        set(ax,'XTick',[],'YTick',[]);
    end

    function refreshTables(which)
        if ~isgraphics(fig), return; end
        if any(strcmp(which,'tx'))&&hasPairs
            set(txTable,'Data',[numberText(txAntennas) num2cell(txTick(:))]);
        end
        if any(strcmp(which,'rx'))&&hasPairs
            set(rxTable,'Data',[numberText(rxAntennas) num2cell(rxTick(:))]);
        end
        if any(strcmp(which,'channels'))
            set(channelTable,'Data',[channelLabels(:) num2cell(chanSel(:))]);
        end
        if any(strcmp(which,'reference'))&&hasReferences
            set(referencePopup,'Value',focusChannel+1);
            if focusChannel>0
                set(referenceText,'String',sprintf('Channel %s; reference channels: %s',channelLabels{focusChannel}, ...
                    labelsText(referenceSets{focusChannel})));
            else
                set(referenceText,'String','Choose a channel to show it with its reference channels.');
            end
        end
        if any(strcmp(which,'datasets'))&&D>1
            styleNames={'solid','dashed','dotted','dash-dot'};
            set(datasetTable,'Data',[names(:) reshape(styleNames(mod(0:D-1,4)+1),[],1) num2cell(dataSel(:))]);
        end
        drawnow; % Tables may otherwise repaint only when the pointer passes over them.
    end

    function refreshControls()
        if ~isgraphics(fig), return; end
        set(quantityPopup,'Value',find(strcmp(offered,opts.Quantity)));
        set(scalePopup,'Value',find(strcmp({'linear','db'},opts.MagnitudeScale)));
        set(phasePopup,'Value',find(strcmp({'radians','degrees'},opts.PhaseUnits)));
        set(unwrapCheck,'Value',opts.UnwrapPhase);
        set(layoutPopup,'Value',find(strcmp({'overlay','individual'},opts.Layout)));
        quantities=axisQuantities(opts.Quantity);
        set(scalePopup,'Enable',onOff(any(strcmp(quantities,'magnitude'))));
        set([phasePopup unwrapCheck],'Enable',onOff(any(strcmp(quantities,'phase'))));
    end

% ---- Callbacks ----
    function uiAction(action)
        try
            action();
        catch problem
            if isgraphics(statusText), set(statusText,'String',problem.message); end
        end
    end

    function onTxEdit(~,event)
        ticks=txTick; ticks(event.Indices(1))=logical(event.NewData);
        uiAction(@()SelectTx(txAntennas(ticks)));
    end

    function onRxEdit(~,event)
        ticks=rxTick; ticks(event.Indices(1))=logical(event.NewData);
        uiAction(@()SelectRx(rxAntennas(ticks)));
    end

    function onChannelEdit(~,event)
        chanSel(event.Indices(1))=logical(event.NewData);
        redraw(sprintf('Channel %s %s.',channelLabels{event.Indices(1)},shownText(event.NewData)));
    end

    function onReferencePopup(~,~)
        uiAction(@()ShowReference(get(referencePopup,'Value')-1));
    end

    function out=labelsText(cs)
        if isempty(cs), out='none'; else, out=strjoin(channelLabels(cs),', '); end
    end

    function onDatasetEdit(~,event)
        dataSel(event.Indices(1))=logical(event.NewData);
        redraw(sprintf('Dataset %s %s.',names{event.Indices(1)},shownText(event.NewData)));
    end

    function onDisplay(~,~)
        scales={'linear','db'}; units={'radians','degrees'}; layouts={'overlay','individual'};
        uiAction(@()SetDisplay('Quantity',offered{get(quantityPopup,'Value')}, ...
            'MagnitudeScale',scales{get(scalePopup,'Value')},'PhaseUnits',units{get(phasePopup,'Value')}, ...
            'UnwrapPhase',get(unwrapCheck,'Value')==1,'Layout',layouts{get(layoutPopup,'Value')}));
        refreshControls();
    end

    function turnPage(step)
        SetDisplay('Page',opts.Page+step);
    end

    function items=perDataset(value,name,allowed)
        if iscell(value)
            if numel(value)~=D
                error(['signalvis:signalViewer:' name],'%s must be text or a cell array with one entry per dataset.',name);
            end
            items=cellfun(@(v)choice(v,name,allowed),value(:).','UniformOutput',false);
        else
            items=repmat({choice(value,name,allowed)},1,D);
        end
    end
end

function keys=availableQuantities(types)
% Quantities that at least one dataset can provide.
keys={};
for t=1:numel(types)
    for q={'magnitude','phase','value','real','imaginary'}
        if supports(types{t},q{1}), keys{end+1}=q{1}; end %#ok<AGROW>
    end
end
if any(strcmp(keys,'magnitude'))&&any(strcmp(keys,'phase')), keys{end+1}='both'; end
end

function keys=quantityKeysAll()
keys={'magnitude','phase','both','value','real','imaginary'};
end

function q=defaultQuantity(type)
switch type
    case 'complex', q='both';
    case 'waveform', q='value';
    otherwise, q=type;
end
end

function quantities=axisQuantities(quantity)
if strcmp(quantity,'both'), quantities={'magnitude','phase'}; else, quantities={quantity}; end
end

function tf=supports(type,quantity)
switch type
    case 'complex', tf=any(strcmp(quantity,{'magnitude','phase','real','imaginary'}));
    case 'waveform', tf=any(strcmp(quantity,{'value','magnitude'}));
    case 'magnitude', tf=strcmp(quantity,'magnitude');
    case 'phase', tf=strcmp(quantity,'phase');
    otherwise, tf=false;
end
end

function value=choice(value,name,allowed)
value=lower(textOption(value,name));
if ~any(strcmp(value,allowed))
    error(['signalvis:signalViewer:' name],'%s must be one of: %s.',name,strjoin(allowed,', '));
end
end

function value=textOption(value,name)
if isstring(value)&&isscalar(value), value=char(value); end
if ~(ischar(value)&&(isrow(value)||isempty(value)))
    error(['signalvis:signalViewer:' name],'%s must be text.',name);
end
value=char(value);
end

function key=unitKey(value,name)
key=lower(textOption(value,name));
if ~any(strcmp(key,{'','samples','hz','khz','mhz','ghz','s','ms','us','ns','ps'}))
    error(['signalvis:signalViewer:' name],'%s must be samples, Hz, kHz, MHz, GHz, s, ms, us, ns or ps.',name);
end
end

function [x,label]=displayAxis(x,units,displayUnits)
freq={'hz','khz','mhz','ghz'}; freqNames={'Hz','kHz','MHz','GHz'}; freqScale=[1 1e3 1e6 1e9];
time={'s','ms','us','ns','ps'}; timeScale=[1 1e-3 1e-6 1e-9 1e-12];
if strcmp(units,displayUnits)&&any(strcmp(units,{'','samples'}))
    if isempty(units), label='Sample axis'; else, label='Sample'; end
    return;
end
if any(strcmp(units,freq))&&any(strcmp(displayUnits,freq))
    x=x*freqScale(strcmp(freq,units))/freqScale(strcmp(freq,displayUnits));
    label=['Frequency (' freqNames{strcmp(freq,displayUnits)} ')'];
elseif any(strcmp(units,time))&&any(strcmp(displayUnits,time))
    x=x*timeScale(strcmp(time,units))/timeScale(strcmp(time,displayUnits));
    label=['Time (' displayUnits ')'];
else
    error('signalvis:signalViewer:DisplayAxisUnits','DisplayAxisUnits must be in the same family as AxisUnits.');
end
end

function antennas=antennaSubset(value,allowed,name)
if isempty(value), antennas=[]; return; end
if ~(isnumeric(value)&&isreal(value)&&isvector(value)&&all(ismember(value(:),allowed)))
    error(['signalvis:signalViewer:' name],'%s must contain antennas from: %s.',name,mat2str(allowed));
end
antennas=unique(double(value(:)).');
end

function idx=indexList(value,count,name)
if isempty(value), idx=[]; return; end
if ~(isnumeric(value)&&isreal(value)&&isvector(value)&&all(value(:)==round(value(:)))&&all(value(:)>=1)&&all(value(:)<=count))
    error(['signalvis:signalViewer:' name],'%s must contain indices between 1 and %d.',name,count);
end
idx=unique(double(value(:)).');
end

function fitColumns(tableColumns)
% Set column widths as fractions of each table's width in pixels, leaving
% room for the vertical scroll bar and the borders.
for k=1:size(tableColumns,1)
    table=tableColumns{k,1};
    if isempty(table)||~isgraphics(table), continue; end
    position=getpixelposition(table);
    usable=max(40,position(3)-24);
    widths=num2cell(max(20,floor(usable*tableColumns{k,2})));
    set(table,'ColumnWidth',widths);
end
end

function table=checkTable(fig,columns,position,callback)
editable=false(1,numel(columns)); editable(end)=true;
formats=repmat({'char'},1,numel(columns)); formats{end}='logical';
table=uitable(fig,'Units','normalized','Position',position,'ColumnName',columns, ...
    'ColumnEditable',editable,'ColumnFormat',formats,'RowName',[],'CellEditCallback',callback);
end

function tableButtons(fig,position,selectAll,selectNone)
w=position(3)/2-.003;
uicontrol(fig,'Style','pushbutton','String','All','Units','normalized', ...
    'Position',[position(1) position(2) w position(4)],'Callback',@(~,~)selectAll());
uicontrol(fig,'Style','pushbutton','String','None','Units','normalized', ...
    'Position',[position(1)+w+.006 position(2) w position(4)],'Callback',@(~,~)selectNone());
end

function handle=label(fig,text,position)
handle=uicontrol(fig,'Style','text','String',text,'Units','normalized','Position',position, ...
    'HorizontalAlignment','left','FontWeight','bold');
end

function colours=lineColours(n)
if n<=7, colours=lines(max(n,1)); else, colours=0.85*hsv(n); end
end

function out=listText(values)
if isempty(values), out='none'; else, out=strjoin(arrayfun(@(v)sprintf('%d',v),values,'UniformOutput',false),' '); end
end

function out=shownText(value)
if value, out='shown'; else, out='hidden'; end
end

function out=onOff(value)
if value, out='on'; else, out='off'; end
end

function cells=numberText(values)
cells=arrayfun(@(v)sprintf('%d',v),values(:),'UniformOutput',false);
end
