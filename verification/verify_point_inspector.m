function results = verify_point_inspector(projectRoot, outputDir)
%VERIFY_POINT_INSPECTOR Scripted checks of signalvis.inspectPointDelays.
%   Requires MERIT on the MATLAB path and uses its example data. Graphics
%   are invisible; callbacks are exercised through the returned inspector API.
if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2, outputDir = tempname; end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
fprintf('Point inspector verification output: %s\n', outputDir);
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));
addpath(projectRoot);
delayFile = which('merit.process.delay');
assert(~isempty(delayFile), 'verification:MERITMissing', ...
    'Add the MERIT folder to the MATLAB path before running this check.');
dataRoot = fullfile(fileparts(fileparts(fileparts(delayFile))), 'data');

names = {'time/sample delays and current selection', ...
    'frequency delay and ns/GHz/mm conversion', ...
    'delay handle receives SI coordinates', 'image mapping and masked grid', ...
    'image dimensions and complex component', 'window and explicit coordinates', ...
    'paging and point selection retention', 'selection failure is atomic', ...
    'invalid inputs precede graphics', 'unrelated figures are preserved', ...
    'actual MERIT delay handle and beamformer image'};
cases = {@timeDelays, @frequencyDelays, @siHandle, @imageMapping, ...
    @imageDimensions, @windowCoordinates, @paging, @atomicFailure, ...
    @invalidInputs, @preserveFigures, @meritIntegration};
results = struct('name', {}, 'passed', {}, 'detail', {});
for k = 1:numel(cases)
    before = findall(0, 'Type', 'figure');
    entry = struct('name', names{k}, 'passed', false, 'detail', '');
    try
        cases{k}();
        entry.passed = true;
        fprintf('PASS: %s\n', entry.name);
    catch problem
        entry.detail = getReport(problem, 'extended', 'hyperlinks', 'off');
        fprintf('FAIL: %s\n%s\n', entry.name, entry.detail);
    end
    results(end+1) = entry; %#ok<AGROW>
    created = findall(0, 'Type', 'figure');
    for figureIndex = 1:numel(created)
        if ~any(created(figureIndex) == before) && ishghandle(created(figureIndex))
            delete(created(figureIndex));
        end
    end
end
fid = fopen(fullfile(outputDir, 'point-inspector-results.txt'), 'w');
if fid < 0, error('verification:Report', 'Cannot create report.'); end
fileCleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'MATLAB %s\n', version);
for k = 1:numel(results)
    status = 'FAIL'; if results(k).passed, status = 'PASS'; end
    fprintf(fid, '%s: %s\n%s', status, results(k).name, results(k).detail);
end
fprintf(fid, '\n%d / %d checks passed.\n', sum([results.passed]), numel(results));
save(fullfile(outputDir, 'point-inspector-results.mat'), 'results');
assert(all([results.passed]), 'verification:Failed', 'Point inspector verification failed.');

    function timeDelays()
        signals = reshape(1:24, 12, 2);
        points = [0 0 0; 1 0 0; 2 0 1];
        shifts = [0 2 -1; 0 -2 3];
        [~, api] = signalvis.inspectPointDelays(signals, (0:11)', points, shifts, ...
            'AxisUnits', 'samples', 'SampleInterval', 1e-10, ...
            'CoordinateUnits', 'mm', 'DelayUnits', 'samples', 'Visible', 'off');
        selected = api.GetSelection();
        assert(selected.PointIndex == 1);
        figureCount = numel(findall(0,'Type','figure'));
        api.SelectPoint(2);
        selected = api.GetSelection();
        assert(selected.PointIndex == 2);
        equalData(selected.OriginalSignals, signals);
        equalData(selected.DelaysSeconds, shifts(:,2)*1e-10);
        % Direct MERIT receives seconds when a time axis is supplied.
        expected = merit.process.delay(signals, shifts(:,2)'*1e-10, (0:11)'*1e-10);
        equalData(selected.DelayedSignals, expected);
        api.SelectPoint(3);
        selected = api.GetSelection();
        assert(selected.PointIndex == 3 && selected.SliceZ == 1);
        equalData(selected.PointMetres, points(3,:)*1e-3);
        api.SelectSlice(.1);
        selected = api.GetSelection();
        assert(selected.PointIndex == 1 && selected.SliceZ == 0);
        assert(numel(findall(0,'Type','figure')) == figureCount, 'Point selection created additional figures.');
    end
    function frequencyDelays()
        signals = [1+1i 2-1i; 2+2i 3-1i; 3-2i 4+1i];
        f = [1;2;3];
        points = [10 0 35; 15 0 35];
        dns = [.1 .3; -.2 -.4];
        [~, api] = signalvis.inspectPointDelays(signals, f, points, dns, ...
            'AxisUnits', 'GHz', 'DisplayAxisUnits', 'MHz', ...
            'CoordinateUnits', 'mm', 'DisplayCoordinateUnits', 'cm', ...
            'DelayUnits', 'ns', 'InitialPoint', 2, 'Visible', 'off');
        selected = api.GetSelection();
        expected = merit.process.delay(signals, dns(:,2)'*1e-9, f*1e9);
        equalData(selected.DelayedSignals, expected);
        equalData(abs(selected.DelayedSignals), abs(signals));
        equalData(selected.CalculationAxis, f*1e9);
        equalData(selected.DelaysSeconds, dns(:,2)*1e-9);
    end
    function siHandle()
        seen = [];
        [~, api] = signalvis.inspectPointDelays([1+1i; 2-1i], [1;2], ...
            [10 0 35;15 0 35], @recordPoint, 'AxisUnits','GHz', ...
            'CoordinateUnits','mm','DelayUnits','ns','Visible','off');
        api.SelectPoint(2);
        equalData(seen, [.015 0 .035]);
        selected = api.GetSelection();
        equalData(selected.DelaysSeconds, -.5e-9);
        function d = recordPoint(p)
            seen = p;
            d = -.5;
        end
    end
    function imageMapping()
        [x,y,z] = ndgrid([0 .01 .02], [0 .03], [0 .01]);
        points = [x(:) y(:) z(:)]; points(2,:) = [];
        P = size(points,1);
        image = [(101:100+P)', (201:200+P)'];
        [~, api] = signalvis.inspectPointDelays([1+1i;2-1i], [1;2], points, ...
            zeros(1,1,P), 'AxisUnits','GHz', 'Image',image, 'ImageIndex',2, ...
            'Axes',{[0 .01 .02],[0 .03],[0 .01]}, 'Visible','off');
        raster = findall(api.MapAxes,'Type','image');
        assert(numel(raster) == 1, 'Expected regular-grid image.');
        assert(isequal(size(get(raster,'CData')),[2 3]), 'Raster dimensions must be y by x.');
        equalData(get(raster,'CData'), [201 NaN 202;203 204 205]);
        assert(strcmp(get(api.MapAxes,'YDir'),'normal'), 'Image y axis is reversed.');
        api.SelectSlice(.01);
        selected = api.GetSelection();
        assert(selected.PointIndex == 6 && selected.SliceZ == .01);
        raster = findall(api.MapAxes,'Type','image');
        equalData(get(raster,'CData'), [206 207 208;209 210 211]);
    end
    function imageDimensions()
        points = [0 0 0;1 0 0;0 1 0];
        image = reshape(1:12, [3 2 2]) + 1i;
        [~, api] = signalvis.inspectPointDelays([1+1i;2-1i], [1;2], points, ...
            zeros(1,1,3), 'AxisUnits','GHz','Image',image,'ImageIndex',[2 2], ...
            'Visible','off');
        markers = findall(api.MapAxes,'Type','scatter');
        assert(~isempty(markers), 'Expected point markers without axes.');
        actual = get(markers(1),'CData');
        equalData(actual, abs(image(:,2,2)));
        api.SelectPoint(3);
        selected = api.GetSelection();
        assert(selected.PointIndex == 3);
    end
    function windowCoordinates()
        signals = reshape(1:24, 12, 2);
        axisNs = (0:11)'*.1;
        [~, api] = signalvis.inspectPointDelays(signals, axisNs, [0 0 0], ...
            [1 -2], 'AxisUnits','ns','DelayUnits','samples', ...
            'Window',@(s) s(1:6,:), 'WindowAxis',axisNs(1:6), 'Visible','off');
        selected = api.GetSelection();
        expected = merit.process.delay(signals,[.1 -.2]*1e-9,axisNs*1e-9);
        equalData(selected.DelayedSignals, expected);
        equalData(selected.ComparedSignals, expected(1:6,:));
        equalData(selected.ComparedAxis, axisNs(1:6)*1e-9);
        equalData(selected.OriginalSignals, signals);
    end
    function paging()
        signals = reshape(1:60,12,5);
        points = [0 0 0;1 0 0;2 0 0];
        [f, api] = signalvis.inspectPointDelays(signals,(0:11)'*1e-10,points, ...
            zeros(5,3),'Layout','individual','ChannelsPerPage',2,'Visible','off');
        api.SelectPoint(2);
        next = findControl(f,'Next');
        invoke(next);
        selected = api.GetSelection();
        assert(selected.Page == 2 && selected.PointIndex == 2);
        api.SelectPoint(3);
        selected = api.GetSelection();
        assert(selected.Page == 2 && selected.PointIndex == 3);
        assert(all(ishghandle(api.OriginalAxes(:))) && all(ishghandle(api.DelayedAxes(:))));
    end
    function atomicFailure()
        [~, api] = signalvis.inspectPointDelays([1;2;3], [0;1;2], ...
            [0 0 0;1 0 0], @badSecond, 'Visible','off');
        caught = false;
        try api.SelectPoint(2); catch, caught = true; end
        assert(caught, 'Programmatic callback failure must be reported.');
        selected = api.GetSelection();
        assert(selected.PointIndex == 1, 'Failed selection changed valid state.');
        function d = badSecond(p)
            if p(1) > 0, error('verification:Deliberate','Deliberate callback failure.'); end
            d = 0;
        end
    end
    function invalidInputs()
        base = {@() signalvis.inspectPointDelays([1;2], [0;1], [0 0], 0, 'Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2;3], [0;1;3], [0 0 0], 0, 'Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2], [1;2], [0 0 0], 0, 'AxisUnits','Hz','Visible','off'), ...
            @() signalvis.inspectPointDelays([1+1i;2-1i], [0;1], [0 0 0], 0, 'AxisUnits','ns','Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2], [0;1], [0 0 0], NaN, 'Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2], [0;1], [0 0 0;1 0 0], 0, 'Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2], [0;1], [0 0 0], 0, 'Image',[1;2], 'Visible','off'), ...
            @() signalvis.inspectPointDelays([1;2], [0;1], [0 0 0], 0, 'Window',@(s)s(1,:), 'Visible','off')};
        for invalidIndex = 1:numel(base)
            count = numel(findall(0,'Type','figure')); caught = false;
            try base{invalidIndex}(); catch problem, caught = true; assert(~isempty(problem.identifier)); end
            assert(caught, 'Invalid inspector input did not fail.');
            assert(numel(findall(0,'Type','figure')) == count, 'Invalid input created a figure.');
        end
    end
    function preserveFigures()
        old = figure('Visible','off'); a = axes('Parent',old); l = plot(a,[0 1],[3 4]);
        signalvis.inspectPointDelays([1;2],[0;1],[0 0 0],0,'Visible','off');
        assert(ishghandle(old) && ishghandle(l)); equalData(get(l,'YData'),[3;4]);
    end
    function meritIntegration()
        dataDir = dataRoot;
        f = dlmread(fullfile(dataDir,'frequencies.csv'));
        pairs = dlmread(fullfile(dataDir,'channel_names.csv'));
        scan1 = dlmread(fullfile(dataDir,'B0_P3_p000.csv'));
        scan2 = dlmread(fullfile(dataDir,'B0_P3_p036.csv'));
        signals = scan1(1:4:end,1:4)-scan2(1:4:end,1:4); f=f(1:4:end);
        antennas = dlmread(fullfile(dataDir,'antenna_locations.csv'));
        points = [0 0 .035;.015 0 .035;.025 .005 .035];
        delays = merit.beamform.get_delays(pairs(1:4,:),antennas,'relative_permittivity',8);
        img = merit.beamform(signals,f,points,delays,merit.beamformers.DAS);
        [fig, api] = signalvis.inspectPointDelays(signals,f,points,delays, ...
            'Image',img,'ChannelLabels',pairs(1:4,:),'CoordinateUnits','m', ...
            'DisplayCoordinateUnits','mm','AxisUnits','Hz','DisplayAxisUnits','GHz','Visible','off');
        api.SelectPoint(2);
        selected = api.GetSelection();
        equalData(selected.DelayedSignals,merit.process.delay(signals,delays(points(2,:)),f));
        print(fig,fullfile(outputDir,'point-inspector-preview.png'),'-dpng','-r120');
    end
end

function equalData(actual,expected)
actual=double(actual(:)); expected=double(expected(:));
assert(isequal(size(actual),size(expected)), 'Array sizes differ.');
assert(isequal(isnan(actual),isnan(expected)), 'NaN locations differ.');
assert(isequal(isinf(actual),isinf(expected)), 'Inf locations differ.');
finite=isfinite(expected);
if any(finite)
    scale=max(abs(expected(finite)));
    tolerance=max(1e-18,1e-10*scale);
    assert(all(abs(actual(finite)-expected(finite)) <= tolerance), 'Numerical values differ.');
end
end
function control=findControl(fig,label)
controls=findall(fig,'Type','uicontrol'); control=[];
for k=1:numel(controls)
    if strcmpi(get(controls(k),'String'),label), control=controls(k); break; end
end
assert(~isempty(control),'Control not found.');
end
function invoke(control)
callback=get(control,'Callback');
if isa(callback,'function_handle')
    callback(control,[]);
elseif iscell(callback)
    feval(callback{1},control,[],callback{2:end});
else
    error('verification:Callback','Expected a callable callback.');
end
drawnow;
end
