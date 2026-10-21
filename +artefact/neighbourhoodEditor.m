function [fig, editor] = neighbourhoodEditor(locations, channelPairs, varargin)
%NEIGHBOURHOODEDITOR Show and edit antenna neighbourhoods and reference channels.
%   [FIG, EDITOR] = artefact.neighbourhoodEditor(LOCATIONS, CHANNELPAIRS, Name,Value,...)
%   shows the N-by-3 antenna LOCATIONS. Each antenna has a neighbourhood,
%   formed automatically (k nearest antennas or all antennas within a
%   distance; see artefact.antennaNeighbours) and editable by hand. From the
%   neighbourhoods follow the reference channels of each channel (see
%   artefact.referenceChannels). CHANNELPAIRS is MERIT's C-by-2
%   channel_names array (Tx, Rx).
%   Choose an antenna in the list or by clicking it to see its neighbours.
%   With Edit neighbours on, clicking another antenna adds it to or removes
%   it from the chosen antenna's neighbourhood. Choose a channel in the
%   channel list to see its reference channels.
%   Options: InitialNeighbours, K (initial k, default 2), MeasuredOnly,
%   Rule (receiver or transmitter), IncludeSelf, AntennaLabels,
%   CoordinateUnits (m, cm, mm), DisplayCoordinateUnits, Title, Visible,
%   Wait. Lengths typed into the figure use DisplayCoordinateUnits; lengths
%   given to EDITOR functions use CoordinateUnits.
%   EDITOR provides GetResult, GetNeighbours, GetReferences, SetNeighbours,
%   ChooseAntenna, ChooseChannel, ClickAt, SetEditMode, ApplyMethod,
%   SetReferenceOptions and Save. They remain usable after the figure is
%   closed.
%   Example:
%     [fig, editor] = artefact.neighbourhoodEditor(antenna_locations, channel_names, ...
%         'DisplayCoordinateUnits', 'mm', 'Wait', true);
%     result = editor.GetResult();

if nargin<2
    error('artefact:neighbourhoodEditor:NotEnoughInputs','Antenna locations and channel pairs are required.');
end
locations=artefact.internal.validateLocations(locations,'artefact:neighbourhoodEditor:Locations');
N=size(locations,1);
channelPairs=artefact.internal.validatePairs(channelPairs,N,'artefact:neighbourhoodEditor:ChannelPairs');
C=size(channelPairs,1);

p=inputParser; p.FunctionName='artefact.neighbourhoodEditor';
addParameter(p,'InitialNeighbours',[]); addParameter(p,'K',2); addParameter(p,'MeasuredOnly',true);
addParameter(p,'Rule','receiver'); addParameter(p,'IncludeSelf',false); addParameter(p,'AntennaLabels',[]);
addParameter(p,'CoordinateUnits','m'); addParameter(p,'DisplayCoordinateUnits','');
addParameter(p,'Title',''); addParameter(p,'Visible','on'); addParameter(p,'Wait',false);
parse(p,varargin{:}); o=p.Results;

coordUnits=unitText(o.CoordinateUnits,'CoordinateUnits');
if isempty(o.DisplayCoordinateUnits), displayUnits=coordUnits; else, displayUnits=unitText(o.DisplayCoordinateUnits,'DisplayCoordinateUnits'); end
factor=unitFactor(coordUnits)/unitFactor(displayUnits);
visible=lower(textValue(o.Visible,'Visible'));
if ~any(strcmp(visible,{'on','off'}))
    error('artefact:neighbourhoodEditor:Visible','Visible must be on or off.');
end
titleText=textValue(o.Title,'Title');
if ~((islogical(o.Wait)||isnumeric(o.Wait))&&isscalar(o.Wait))
    error('artefact:neighbourhoodEditor:Wait','Wait must be true or false.');
end
waitForDone=logical(o.Wait);
if waitForDone&&strcmp(visible,'off')
    error('artefact:neighbourhoodEditor:Wait','Wait requires a visible figure.');
end
if ~((islogical(o.MeasuredOnly)||isnumeric(o.MeasuredOnly))&&isscalar(o.MeasuredOnly))
    error('artefact:neighbourhoodEditor:MeasuredOnly','MeasuredOnly must be true or false.');
end
measuredOnly=logical(o.MeasuredOnly);
if isempty(o.AntennaLabels)
    labels=arrayfun(@(k)sprintf('%d',k),1:N,'UniformOutput',false);
elseif isnumeric(o.AntennaLabels)&&numel(o.AntennaLabels)==N
    labels=arrayfun(@(v)sprintf('%g',v),o.AntennaLabels(:).','UniformOutput',false);
elseif (iscellstr(o.AntennaLabels)||isstring(o.AntennaLabels))&&numel(o.AntennaLabels)==N
    labels=cellstr(o.AntennaLabels); labels=labels(:).';
else
    error('artefact:neighbourhoodEditor:AntennaLabels','AntennaLabels must contain one label per antenna.');
end
if isempty(o.InitialNeighbours)
    neighbours=artefact.antennaNeighbours(locations,channelPairs,'nearest','K',o.K,'MeasuredOnly',measuredOnly);
else
    neighbours=o.InitialNeighbours;
    if ~(iscell(neighbours)&&numel(neighbours)==N)
        error('artefact:neighbourhoodEditor:InitialNeighbours','InitialNeighbours must be a cell array with one element per antenna.');
    end
    neighbours=neighbours(:);
end
rule=o.Rule; includeSelf=o.IncludeSelf;
% Validate neighbourhoods and reference options before graphics.
[references,refInfo]=artefact.referenceChannels(neighbours,channelPairs,'Rule',rule,'IncludeSelf',includeSelf);
for i=1:N, neighbours{i}=unique(double(neighbours{i}(:)).'); end
rule=lower(char(rule)); includeSelf=logical(includeSelf);

currentAntenna=1; currentChannel=0; editMode=false; history={}; waiting=false;
P=locations*factor;
extent=max(max(P,[],1)-min(P,[],1)); if extent==0, extent=1; end
candidates=artefact.internal.candidateNeighbours(channelPairs,N,measuredOnly);
nearestDistance=zeros(1,N);
for a=1:N
    pool=find(candidates(a,:));
    if isempty(pool), nearestDistance(a)=NaN; else, nearestDistance(a)=min(sqrt(sum((P(pool,:)-P(a,:)).^2,2))); end
end
if all(isnan(nearestDistance)), defaultDistance=1; else, defaultDistance=roundTo(1.2*median(nearestDistance(~isnan(nearestDistance)))); end

% ---- Figure ----
fig=figure('Visible',visible,'Name','Antenna neighbourhoods','NumberTitle','off', ...
    'Units','normalized','Position',[.08 .08 .84 .8]);
ax=axes('Parent',fig,'Units','normalized','Position',[.06 .15 .5 .74]);
hold(ax,'on'); grid(ax,'on'); set(ax,'DataAspectRatio',[1 1 1]);
xlabel(ax,['x (' displayUnits ')']); ylabel(ax,['y (' displayUnits ')']); zlabel(ax,['z (' displayUnits ')']);
referenceLines=plot3(ax,NaN,NaN,NaN,'-','Color',[.93 .6 .1],'LineWidth',1.5,'HitTest','off');
neighbourLines=plot3(ax,NaN,NaN,NaN,'--','Color',[0 .45 .74],'LineWidth',1.2,'HitTest','off');
channelLine=plot3(ax,NaN,NaN,NaN,'-','Color',[.85 0 0],'LineWidth',3,'HitTest','off');
markers=scatter3(ax,P(:,1),P(:,2),P(:,3),110,repmat([.6 .6 .6],N,1),'filled', ...
    'MarkerEdgeColor','k','ButtonDownFcn',@onClick);
offset=0.03*extent;
labelHandles=text(ax,P(:,1)+offset,P(:,2)+offset,P(:,3)+offset,labels,'FontSize',9,'HitTest','off');
set(ax,'ButtonDownFcn',@onClick);
view(ax,3);
pad=0.08*extent;
lo=min(P,[],1)-pad; hi=max(P,[],1)+pad;
set(ax,'XLim',[lo(1) hi(1)],'YLim',[lo(2) hi(2)],'ZLim',[lo(3) hi(3)]);

uicontrol(fig,'Style','text','String','View','Units','normalized','Position',[.06 .93 .04 .03],'HorizontalAlignment','left');
viewPopup=uicontrol(fig,'Style','popupmenu','String',{'3-D','Top (x-y)','Front (x-z)','Side (y-z)'}, ...
    'Units','normalized','Position',[.1 .932 .12 .035],'Callback',@onView);
rotateToggle=uicontrol(fig,'Style','togglebutton','String','Rotate','Units','normalized', ...
    'Position',[.235 .932 .08 .035],'Callback',@onRotate);
editToggle=uicontrol(fig,'Style','togglebutton','String','Edit neighbours','Units','normalized', ...
    'Position',[.33 .932 .12 .035],'Callback',@onEditToggle);
statusText=uicontrol(fig,'Style','text','String','','Units','normalized', ...
    'Position',[.06 .02 .5 .07],'HorizontalAlignment','left');

x0=.6; w=.37;
uicontrol(fig,'Style','text','String','Antennas (choose one to see its neighbours)','Units','normalized', ...
    'Position',[x0 .935 w .03],'HorizontalAlignment','left','FontWeight','bold');
antennaList=uicontrol(fig,'Style','listbox','String',{''},'Value',1, ...
    'Units','normalized','Position',[x0 .7 w .235],'Callback',@onAntennaList);

autoPanel=uipanel(fig,'Title','Automatic neighbourhoods','Units','normalized','Position',[x0 .44 w .245]);
methodNames={'nearest','distance'};
uiLabel(autoPanel,'Method',[.03 .78 .2 .13]);
methodPopup=uicontrol(autoPanel,'Style','popupmenu','String',{'k nearest antennas','Within a distance'}, ...
    'Units','normalized','Position',[.24 .79 .73 .13],'Callback',@onMethod);
uiLabel(autoPanel,'k',[.03 .56 .2 .13]);
kEdit=uicontrol(autoPanel,'Style','edit','String',sprintf('%d',o.K),'Units','normalized','Position',[.24 .57 .2 .14]);
uiLabel(autoPanel,['Distance (' displayUnits ')'],[.5 .56 .22 .13]);
distanceEdit=uicontrol(autoPanel,'Style','edit','String',sprintf('%g',defaultDistance),'Units','normalized','Position',[.75 .57 .22 .14]);
measuredCheck=uicontrol(autoPanel,'Style','checkbox','String','Only antennas with a measured channel','Value',measuredOnly, ...
    'Units','normalized','Position',[.03 .35 .94 .14]);
uicontrol(autoPanel,'Style','pushbutton','String','Apply to all antennas','Units','normalized', ...
    'Position',[.03 .06 .45 .2],'Callback',@(~,~)uiAction(@()applyFromControls(1:N)));
uicontrol(autoPanel,'Style','pushbutton','String','Apply to chosen antenna','Units','normalized', ...
    'Position',[.52 .06 .45 .2],'Callback',@onApplyChosen);

refPanel=uipanel(fig,'Title','Reference channels','Units','normalized','Position',[x0 .09 w .34]);
uiLabel(refPanel,'Rule',[.03 .86 .2 .09]);
rulePopup=uicontrol(refPanel,'Style','popupmenu','String',{'Receiver neighbourhood','Transmitter neighbourhood'}, ...
    'Value',1+strcmp(rule,'transmitter'),'Units','normalized','Position',[.24 .87 .73 .09],'Callback',@onReferenceOptions);
selfCheck=uicontrol(refPanel,'Style','checkbox','String','Include the channel itself','Value',includeSelf, ...
    'Units','normalized','Position',[.03 .74 .94 .09],'Callback',@onReferenceOptions);
uiLabel(refPanel,'Channels (choose one to see its reference channels)',[.03 .64 .94 .08]);
channelList=uicontrol(refPanel,'Style','listbox','String',{''},'Min',0,'Max',2,'Value',[], ...
    'Units','normalized','Position',[.03 .2 .94 .44],'Callback',@onChannelList);
summaryText=uicontrol(refPanel,'Style','text','String','','Units','normalized','Position',[.03 .02 .94 .16], ...
    'HorizontalAlignment','left');

uicontrol(fig,'Style','pushbutton','String','Save...','Units','normalized','Position',[x0 .02 .1 .05], ...
    'Callback',@onSave);
uicontrol(fig,'Style','pushbutton','String','Done','Units','normalized','Position',[x0+w-.1 .02 .1 .05], ...
    'Callback',@onDone);

editor=struct('Figure',fig,'Axes',ax,'Markers',markers,'Labels',labelHandles,'AntennaList',antennaList, ...
    'ChannelList',channelList,'Status',statusText, ...
    'GetResult',@GetResult,'GetNeighbours',@GetNeighbours,'GetReferences',@GetReferences, ...
    'SetNeighbours',@SetNeighbours,'ChooseAntenna',@ChooseAntenna,'ChooseChannel',@ChooseChannel, ...
    'ClickAt',@ClickAt,'SetEditMode',@SetEditMode,'ApplyMethod',@ApplyMethod, ...
    'SetReferenceOptions',@SetReferenceOptions,'Save',@Save);
onMethod();
refresh('Choose an antenna to see its neighbours; switch on Edit neighbours to change them.');
if waitForDone
    waiting=true;
    uiwait(fig);
    waiting=false;
end

% ---- Programmatic interface ----
    function result=GetResult()
        result=struct('Neighbours',{neighbours},'References',{references},'Rule',rule, ...
            'IncludeSelf',includeSelf,'NoReference',refInfo.NoReference,'Missing',{refInfo.Missing}, ...
            'ChannelPairs',channelPairs,'Locations',locations,'CoordinateUnits',coordUnits, ...
            'History',{history});
    end

    function out=GetNeighbours()
        out=neighbours;
    end

    function out=GetReferences()
        out=references;
    end

    function SetNeighbours(antenna,list)
        antenna=antennaIndex(antenna);
        if isempty(list), list=zeros(1,0); end
        if ~(isnumeric(list)&&isreal(list)&&isvector(list)&&all(list==round(list))&&all(list>=1)&&all(list<=N))
            error('artefact:neighbourhoodEditor:Neighbours','Neighbours must be antenna numbers between 1 and %d.',N);
        end
        if any(list==antenna)
            error('artefact:neighbourhoodEditor:Neighbours','An antenna cannot be its own neighbour.');
        end
        updated=neighbours; updated{antenna}=unique(double(list(:)).');
        commit(updated,sprintf('Neighbours of antenna %s set to %s',labels{antenna},labelList(updated{antenna})));
    end

    function ChooseAntenna(antenna)
        currentAntenna=antennaIndex(antenna); currentChannel=0;
        refresh(sprintf('Antenna %s: neighbours %s.',labels{currentAntenna},labelList(neighbours{currentAntenna})));
    end

    function ChooseChannel(c)
        if ~(isnumeric(c)&&isscalar(c)&&c==round(c)&&c>=1&&c<=C)
            error('artefact:neighbourhoodEditor:Channel','Channel must be a number between 1 and %d.',C);
        end
        currentChannel=double(c);
        refresh(sprintf('Channel %s: reference channels %s.',channelLabel(c),channelText(references{c})));
    end

    function ClickAt(viewLine)
        % Act on the antenna nearest to a view line given as a 2-by-3 array
        % in display units, as the axes CurrentPoint gives for a click.
        if ~(isnumeric(viewLine)&&isequal(size(viewLine),[2 3])&&all(isfinite(viewLine(:))))
            error('artefact:neighbourhoodEditor:ClickAt','The view line must be a finite 2-by-3 array.');
        end
        u=viewLine(2,:)-viewLine(1,:);
        if norm(u)==0, u=[0 0 1]; else, u=u/norm(u); end
        v=P-viewLine(1,:);
        d=sqrt(sum((v-(v*u.')*u).^2,2));
        [best,k]=min(d);
        if best>0.08*extent
            refresh('No antenna near the click.'); return;
        end
        if ~editMode
            ChooseAntenna(k);
        elseif k==currentAntenna
            refresh('An antenna cannot be its own neighbour; click another antenna.');
        else
            list=neighbours{currentAntenna};
            if any(list==k), list(list==k)=[]; action='removed from'; else, list=[list k]; action='added to'; end
            updated=neighbours; updated{currentAntenna}=unique(list);
            commit(updated,sprintf('Antenna %s %s the neighbours of antenna %s',labels{k},action,labels{currentAntenna}));
        end
    end

    function SetEditMode(value)
        editMode=logical(value);
        if isgraphics(fig), set(editToggle,'Value',editMode); end
        if editMode
            refresh(sprintf('Edit mode: click antennas to add them to or remove them from the neighbours of antenna %s.',labels{currentAntenna}));
        else
            refresh('Edit mode off: clicks choose antennas.');
        end
    end

    function ApplyMethod(method,varargin)
        % ApplyMethod(METHOD, Name,Value,...) passes options to
        % artefact.antennaNeighbours; Antennas limits the antennas whose
        % neighbourhoods are replaced (default all).
        target=1:N; rest={};
        for k=1:2:numel(varargin)
            if k+1>numel(varargin)
                error('artefact:neighbourhoodEditor:ApplyMethod','Options must be name-value pairs.');
            end
            if (ischar(varargin{k})||isstring(varargin{k}))&&strcmpi(varargin{k},'Antennas')
                target=varargin{k+1};
            else
                rest=[rest varargin(k:k+1)]; %#ok<AGROW>
            end
        end
        found=artefact.antennaNeighbours(locations,channelPairs,method,'Antennas',target,rest{:});
        target=unique(double(target(:)).');
        updated=neighbours; updated(target)=found(target);
        commit(updated,sprintf('Method %s applied to %d antennas (%s)',lower(char(method)),numel(target),describe(rest)));
    end

    function SetReferenceOptions(varargin)
        newRule=rule; newSelf=includeSelf;
        for k=1:2:numel(varargin)
            if k+1>numel(varargin)
                error('artefact:neighbourhoodEditor:SetReferenceOptions','Options must be name-value pairs.');
            end
            switch lower(char(varargin{k}))
                case 'rule', newRule=varargin{k+1};
                case 'includeself', newSelf=varargin{k+1};
                otherwise
                    error('artefact:neighbourhoodEditor:SetReferenceOptions','Options are Rule and IncludeSelf.');
            end
        end
        [newReferences,newInfo]=artefact.referenceChannels(neighbours,channelPairs,'Rule',newRule,'IncludeSelf',newSelf);
        rule=lower(char(newRule)); includeSelf=logical(newSelf);
        references=newReferences; refInfo=newInfo;
        message=sprintf('Reference rule: %s neighbourhood; channel itself %s',rule,ternary(includeSelf,'included','left out'));
        history{end+1}=message;
        syncReferenceControls();
        refresh([message '.']);
    end

    function Save(file)
        neighbourhoods=GetResult(); %#ok<NASGU>
        save(file,'neighbourhoods');
        refresh(sprintf('Saved to %s.',file));
    end

% ---- Internal state ----
    function commit(updated,message)
        [newReferences,newInfo]=artefact.referenceChannels(updated,channelPairs,'Rule',rule,'IncludeSelf',includeSelf);
        neighbours=updated; references=newReferences; refInfo=newInfo;
        history{end+1}=message;
        refresh([message '.']);
    end

    function a=antennaIndex(a)
        if ~(isnumeric(a)&&isscalar(a)&&a==round(a)&&a>=1&&a<=N)
            error('artefact:neighbourhoodEditor:Antenna','Antenna must be a number between 1 and %d.',N);
        end
        a=double(a);
    end

    function out=labelList(idx)
        if isempty(idx), out='none'; else, out=strjoin(labels(idx),' '); end
    end

    function out=channelLabel(c)
        out=sprintf('%s-%s',labels{channelPairs(c,1)},labels{channelPairs(c,2)});
    end

    function out=channelText(cs)
        if isempty(cs), out='none'; else, out=strjoin(arrayfun(@channelLabel,cs,'UniformOutput',false),' '); end
    end

% ---- Graphics ----
    function refresh(message)
        if ~isgraphics(fig), return; end
        colours=repmat([.6 .6 .6],N,1);
        lineData=nan(0,3); refData=nan(0,3); chanData=nan(0,3);
        if currentChannel>0
            c=currentChannel;
            chanData=[P(channelPairs(c,1),:); P(channelPairs(c,2),:)];
            for r=references{c}
                refData=[refData; P(channelPairs(r,1),:); P(channelPairs(r,2),:); nan(1,3)]; %#ok<AGROW>
            end
            colours(unique(channelPairs(references{c},:)),:)=repmat([.93 .6 .1],numel(unique(channelPairs(references{c},:))),1);
            colours(channelPairs(c,:),:)=repmat([.85 0 0],2,1);
        else
            a=currentAntenna;
            for m=neighbours{a}
                lineData=[lineData; P(a,:); P(m,:); nan(1,3)]; %#ok<AGROW>
            end
            colours(neighbours{a},:)=repmat([0 .45 .74],numel(neighbours{a}),1);
            colours(a,:)=[.85 0 0];
        end
        set(markers,'CData',colours);
        setLine(neighbourLines,lineData); setLine(referenceLines,refData); setLine(channelLine,chanData);
        entries=arrayfun(@(a)sprintf('Antenna %s: %d neighbours [%s]',labels{a},numel(neighbours{a}),labelList(neighbours{a})), ...
            1:N,'UniformOutput',false);
        set(antennaList,'String',entries,'Value',currentAntenna);
        if C==0
            set(channelList,'String',{'(no channel pairs)'},'Value',[]);
        else
            entries=arrayfun(@(c)sprintf('%s: %d reference channels',channelLabel(c),numel(references{c})),1:C,'UniformOutput',false);
            if currentChannel>0, value=currentChannel; else, value=[]; end
            set(channelList,'String',entries,'Value',value);
        end
        sizes=cellfun(@numel,references);
        if C==0
            set(summaryText,'String','No channel pairs supplied.');
        else
            set(summaryText,'String',sprintf('%d channels; reference sets of %d to %d channels; %d channels without a reference.', ...
                C,min(sizes),max(sizes),numel(refInfo.NoReference)));
        end
        if isempty(titleText)
            if currentChannel>0
                title(ax,sprintf('Channel %s (red) and its reference channels (orange)',channelLabel(currentChannel)),'Interpreter','none');
            else
                title(ax,sprintf('Antenna %s (red) and its neighbours (blue)',labels{currentAntenna}),'Interpreter','none');
            end
        else
            title(ax,titleText,'Interpreter','none');
        end
        set(statusText,'String',message);
    end

    function setLine(handle,xyz)
        if isempty(xyz), xyz=nan(1,3); end
        set(handle,'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3));
    end

    function syncReferenceControls()
        if ~isgraphics(fig), return; end
        set(rulePopup,'Value',1+strcmp(rule,'transmitter'));
        set(selfCheck,'Value',includeSelf);
    end

% ---- Callbacks ----
    function uiAction(action)
        try
            action();
        catch problem
            if isgraphics(statusText), set(statusText,'String',problem.message); end
        end
    end

    function onClick(~,~)
        if get(rotateToggle,'Value')==1, return; end
        uiAction(@()ClickAt(get(ax,'CurrentPoint')));
    end

    function onAntennaList(~,~)
        uiAction(@()ChooseAntenna(get(antennaList,'Value')));
    end

    function onChannelList(~,~)
        value=get(channelList,'Value');
        if C==0||isempty(value), return; end
        uiAction(@()ChooseChannel(value(1)));
    end

    function onView(~,~)
        switch get(viewPopup,'Value')
            case 1, view(ax,3);
            case 2, view(ax,0,90);
            case 3, view(ax,0,0);
            case 4, view(ax,90,0);
        end
    end

    function onRotate(~,~)
        if get(rotateToggle,'Value')==1
            rotate3d(fig,'on');
            set(statusText,'String','Rotation is on; switch it off to click antennas.');
        else
            rotate3d(fig,'off');
            set(statusText,'String','Rotation is off.');
        end
    end

    function onEditToggle(~,~)
        uiAction(@()SetEditMode(get(editToggle,'Value')==1));
    end

    function onMethod(~,~)
        nearest=strcmp(methodNames{get(methodPopup,'Value')},'nearest');
        set(kEdit,'Enable',ternary(nearest,'on','off'));
        set(distanceEdit,'Enable',ternary(nearest,'off','on'));
    end

    function onApplyChosen(~,~)
        % Reads the chosen antenna when clicked, not when the window was built.
        uiAction(@()applyFromControls(currentAntenna));
    end

    function applyFromControls(target)
        method=methodNames{get(methodPopup,'Value')};
        if strcmp(method,'nearest')
            args={'K',numberFrom(kEdit,'k')};
        else
            args={'Distance',numberFrom(distanceEdit,'Distance')/factor};
        end
        ApplyMethod(method,'Antennas',target,'MeasuredOnly',get(measuredCheck,'Value')==1,args{:});
    end

    function onReferenceOptions(~,~)
        rules={'receiver','transmitter'};
        uiAction(@()SetReferenceOptions('Rule',rules{get(rulePopup,'Value')},'IncludeSelf',get(selfCheck,'Value')==1));
    end

    function onSave(~,~)
        [file,folder]=uiputfile('*.mat','Save neighbourhoods','neighbourhoods.mat');
        if isequal(file,0), return; end
        uiAction(@()Save(fullfile(folder,file)));
    end

    function onDone(~,~)
        if waiting, uiresume(fig); end
        delete(fig);
    end

    function value=numberFrom(edit,name)
        value=str2double(get(edit,'String'));
        if ~isfinite(value)
            error('artefact:neighbourhoodEditor:Value','%s must be a number.',name);
        end
    end
end

function out=ternary(condition,a,b)
if condition, out=a; else, out=b; end
end

function value=roundTo(value)
if ~(value>0), value=1; return; end
scale=10^(floor(log10(value))-1);
value=round(value/scale)*scale;
end

function f=unitFactor(units)
switch units
    case 'm', f=1;
    case 'cm', f=1e-2;
    case 'mm', f=1e-3;
end
end

function units=unitText(value,name)
units=lower(textValue(value,name));
if ~any(strcmp(units,{'m','cm','mm'}))
    error(['artefact:neighbourhoodEditor:' name],'%s must be m, cm or mm.',name);
end
end

function value=textValue(value,name)
if isstring(value)&&isscalar(value), value=char(value); end
if ~(ischar(value)&&(isrow(value)||isempty(value)))
    error(['artefact:neighbourhoodEditor:' name],'%s must be text.',name);
end
value=char(value);
end

function handle=uiLabel(parent,label,position)
handle=uicontrol(parent,'Style','text','String',label,'Units','normalized','Position',position, ...
    'HorizontalAlignment','left');
end

function out=describe(args)
parts=cell(1,numel(args)/2);
for k=1:2:numel(args)
    value=args{k+1};
    if ischar(value)||isstring(value), shown=char(value); elseif islogical(value), shown=mat2str(value); else, shown=mat2str(value,6); end
    parts{(k+1)/2}=sprintf('%s=%s',char(args{k}),shown);
end
out=strjoin(parts,', ');
end
