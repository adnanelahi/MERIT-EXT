function renderChannels(ax,data,x,labels,qnames,layout,o,axisLabel,N)
%RENDERCHANNELS Draw into existing axes, allowing page changes to reuse them.
nc=numel(labels); nq=numel(data); per=o.ChannelsPerPage;
if strcmp(layout,'individual')
    page=getappdata(ancestor(ax(1),'figure'),'signalvisPage'); if isempty(page), page=1; end
    first=(page-1)*per+1; last=min(page*per,nc); visibleCount=last-first+1;
    for i=1:numel(ax)
        cla(ax(i),'reset'); set(ax(i),'Visible','off');
        trace=floor((i-1)/nq)+1; q=mod(i-1,nq)+1;
        if trace<=visibleCount
            set(ax(i),'Visible','on'); idx=first+trace-1; y=data{q}(:,idx);
            if N==1, plot(ax(i),x,y,'o'); else, plot(ax(i),x,y,'-'); end
            if isempty(o.Title), title(ax(i),labels{idx},'Interpreter','none'); else, title(ax(i),[o.Title ' - ' labels{idx}],'Interpreter','none'); end
            ylabel(ax(i),qnames{q},'Interpreter','none'); xlabel(ax(i),axisLabel,'Interpreter','none'); grid(ax(i),'on');
        end
    end
else
    for q=1:nq
        cla(ax(q)); hold(ax(q),'on');
        for c=1:nc
            if N==1, plot(ax(q),x,data{q}(:,c),'o','DisplayName',labels{c}); else, plot(ax(q),x,data{q}(:,c),'-','DisplayName',labels{c}); end
        end
        hold(ax(q),'off'); ylabel(ax(q),qnames{q},'Interpreter','none'); xlabel(ax(q),axisLabel,'Interpreter','none'); grid(ax(q),'on');
        showLegend=strcmpi(o.Legend,'on')||(strcmpi(o.Legend,'auto')&&nc<=12);
        % Some MATLAB releases read text after 'show' as entry labels, so set properties on the object.
        if showLegend, lg=legend(ax(q),'show'); set(lg,'Location','best','Interpreter','none'); end
    end
end
if ~isempty(o.Title) && strcmp(layout,'overlay'), for q=1:nq, title(ax(q),o.Title,'Interpreter','none'); end, end
if ~isempty(o.XLabel)
    for i=1:numel(ax)
        if strcmp(get(ax(i),'Visible'),'on'), xlabel(ax(i),o.XLabel,'Interpreter','none'); end
    end
end
if ~isempty(o.YLabel)
    yl=o.YLabel;
    for i=1:numel(ax)
        if ~strcmp(get(ax(i),'Visible'),'on'), continue; end
        q=mod(i-1,nq)+1;
        if iscell(yl)
            if numel(yl)==nq, label=yl{q}; else, label=yl{1}; end
        else
            label=yl;
        end
        ylabel(ax(i),label,'Interpreter','none');
    end
end
end
