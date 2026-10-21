function results = verify_neighbourhoods(projectRoot, outputDir)
%VERIFY_NEIGHBOURHOODS Scripted checks of antenna neighbourhoods and reference channels.
%   Uses MERIT's example data, found through MERIT on the MATLAB path.
%   Figures are invisible; the editor is exercised through its returned
%   functions and callbacks.
if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2, outputDir = tempname; end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
fprintf('Neighbourhood verification output: %s\n', outputDir);
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));
addpath(projectRoot);
delayFile = which('merit.process.delay');
assert(~isempty(delayFile), 'verification:MERITMissing', ...
    'Add the MERIT folder to the MATLAB path before running this check.');
dataRoot = fullfile(fileparts(fileparts(fileparts(delayFile))), 'data');
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);

names = {'k nearest neighbours', 'neighbours within a distance', 'candidate restriction and subsets', ...
    'receiver and transmitter rules', 'reciprocity, missing channels and monostatic data', ...
    'editor operations', 'editor clicks and callbacks', 'invalid inputs precede graphics', ...
    'unrelated figures and closing', 'MERIT data and preview', 'average subtraction'};
cases = {@nearest, @withinDistance, @candidates, @rules, @reciprocity, ...
    @editorOperations, @editorClicks, @invalidInputs, @figuresAndClosing, @meritPreview, @averageSubtraction};
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
    delete(setdiff(findall(0, 'Type', 'figure'), before));
    results(end+1) = entry; %#ok<AGROW>
end
assert(all([results.passed]), 'verification:Failed', 'Neighbourhood verification failed.');

    function nearest()
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        assert(isequal(size(n), [24 1]) && all(cellfun(@numel, n) == 2));
        assert(isequal(n{1}, [2 10]), 'Adjacent antennas in ring 1, equal distances ordered by number.');
        assert(isequal(n{3}, [2 4]));
        assert(isequal(n{10}, [1 9]) && isequal(n{21}, [22 24]));
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 0);
        assert(all(cellfun(@isempty, n)));
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 30);
        assert(numel(n{1}) == 9 && numel(n{21}) == 3, 'K beyond the candidates gives all candidates.');
        square = [0 0 0; 1 0 0; 0 1 0; 1 1 0];
        n = artefact.antennaNeighbours(square, [], 'nearest', 'K', 1, 'MeasuredOnly', false);
        assert(isequal(n{1}, 2) && isequal(n{4}, 2), 'Ties are broken by the lower antenna number.');
    end

    function withinDistance()
        n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.045);
        assert(isequal(n{1}, [2 10]));
        n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.09);
        assert(isequal(n{1}, [2 3 9 10]), 'Within 90 mm: antennas one and two places apart.');
        n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0);
        assert(all(cellfun(@isempty, n)));
        n = artefact.antennaNeighbours(locations, pairs);
        assert(isequal(n, artefact.antennaNeighbours(locations, pairs, 'distance')), 'The default method is distance.');
        assert(isequal(n, artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2)), ...
            'The default distance gives every Galway antenna its two adjacent antennas, including ring 3.');
        assert(isequal(artefact.antennaNeighbours(locations, pairs, 'Distance', 0.09), ...
            artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.09)), 'Distance without a method.');
        [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
        result = e.GetResult();
        delete(fig);
        assert(isequal(result.Neighbours, n), 'The editor starts with the default distance.');
    end

    function candidates()
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2, 'MeasuredOnly', false);
        assert(isequal(n{1}, [11 20]), 'Without the restriction, antennas 11 and 20 in ring 2 are nearest (34 mm).');
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2, 'Antennas', [1 5]);
        assert(~isempty(n{1}) && ~isempty(n{5}) && all(cellfun(@isempty, n([2:4 6:24]))));
        n = artefact.antennaNeighbours(locations, [1 2; 2 3], 'nearest', 'K', 5);
        assert(isequal(n{1}, 2) && isequal(n{2}, [1 3]) && isempty(n{4}), 'Only antennas with a measured channel are candidates.');
        expectError(@() artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', -1), 'artefact:antennaNeighbours:K');
        expectError(@() artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', -1), 'artefact:antennaNeighbours:Distance');
        expectError(@() artefact.antennaNeighbours(locations, pairs, 'kmeans', 'K', 2), 'artefact:antennaNeighbours:Method');
        expectError(@() artefact.antennaNeighbours(locations, [1 30], 'nearest', 'K', 2), 'artefact:antennaNeighbours:ChannelPairs');
    end

    function rules()
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        r = artefact.referenceChannels(n, pairs);
        assert(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,4)])), 'Receiver rule for 1-3: 1-2 and 1-4.');
        r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
        assert(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,10)])), 'Transmitter rule for 1-3: 1-2 and 1-10.');
        r = artefact.referenceChannels(n, pairs, 'IncludeSelf', true);
        assert(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,3) channel(1,4)])));
        r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
        assert(isequal(r{channel(1,2)}, channel(1,10)), 'The channel itself (1-2) is left out of its reference.');
        expectError(@() artefact.referenceChannels(n, pairs, 'Rule', 'both'), 'artefact:referenceChannels:Rule');
        bad = n; bad{1} = [1 2];
        expectError(@() artefact.referenceChannels(bad, pairs), 'artefact:referenceChannels:Neighbours');
    end

    function reciprocity()
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        [r, info] = artefact.referenceChannels(n, pairs);
        assert(isequal(r{channel(9,10)}, channel(1,9)), ...
            'Receiver rule for 9-10: neighbours of 10 are 1 and 9; 9 is the transmitter, and 9-1 is measured as 1-9.');
        assert(isempty(info.NoReference));
        r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
        assert(isequal(r{channel(9,10)}, channel(8,9)), 'Transmitter rule for 9-10: 9-8 is measured as 8-9.');
        hand = n; hand{1} = 11;
        [r, info] = artefact.referenceChannels(hand, pairs, 'Rule', 'transmitter');
        c = channel(1,2);
        assert(isempty(r{c}) && isequal(info.Missing{c}, [1 11]) && any(info.NoReference == c), ...
            'An unmeasured reference channel is omitted and reported.');
        line = [0 0 0; 1 0 0; 2 0 0; 3 0 0];
        mono = [1 1; 2 2; 3 3; 4 4];
        nm = artefact.antennaNeighbours(line, mono, 'nearest', 'K', 2);
        assert(isequal(nm{1}, [2 3]) && isequal(nm{3}, [2 4]));
        rm = artefact.referenceChannels(nm, mono);
        assert(isequal(rm{1}, [2 3]) && isequal(rm{3}, [2 4]), 'Monostatic: the neighbours'' own channels.');
        rm = artefact.referenceChannels(nm, mono, 'Rule', 'transmitter');
        assert(isequal(rm{1}, [2 3]), 'Both rules agree for monostatic channels.');
    end

    function editorOperations()
        [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        assert(isequal(e.GetNeighbours(), n), 'The editor starts from the two nearest antennas.');
        assert(isequal(e.GetReferences(), artefact.referenceChannels(n, pairs)));
        e.SetNeighbours(1, [2 3 10]);
        neighbours = e.GetNeighbours();
        assert(isequal(neighbours{1}, [2 3 10]) && isequal(neighbours(2:end), n(2:end)), 'Only antenna 1 changes.');
        e.ApplyMethod('distance', 'Distance', 0.09, 'Antennas', 21);
        neighbours = e.GetNeighbours();
        assert(isequal(neighbours{21}, [22 23 24]) && isequal(neighbours{1}, [2 3 10]));
        e.SetReferenceOptions('Rule', 'transmitter', 'IncludeSelf', true);
        result = e.GetResult();
        assert(strcmp(result.Rule, 'transmitter') && result.IncludeSelf);
        assert(isequal(result.References, artefact.referenceChannels(result.Neighbours, pairs, 'Rule', 'transmitter', 'IncludeSelf', true)));
        expectError(@() e.SetNeighbours(1, 1), 'artefact:neighbourhoodEditor:Neighbours');
        expectError(@() e.SetReferenceOptions('Rule', 'both'), 'artefact:referenceChannels:Rule');
        result = e.GetResult();
        assert(numel(result.History) == 3, 'Failed operations are not recorded.');
        file = fullfile(outputDir, 'neighbourhoods.mat');
        e.Save(file);
        loaded = load(file);
        assert(isequal(loaded.neighbourhoods.Neighbours, result.Neighbours));
    end

    function editorClicks()
        [fig, e] = artefact.neighbourhoodEditor(locations * 1000, pairs, 'CoordinateUnits', 'mm', 'Visible', 'off');
        at = @(a) [locations(a, 1:2) * 1000 500; locations(a, 1:2) * 1000 -500];
        e.ClickAt(at(5));
        state = e.GetResult();
        assert(isequal(state.Neighbours{5}, [4 6]));
        e.SetEditMode(true);
        e.ClickAt(at(8));
        neighbours = e.GetNeighbours();
        assert(isequal(neighbours{5}, [4 6 8]), 'In edit mode a click adds the antenna to the chosen neighbourhood.');
        e.ClickAt(at(8));
        e.ClickAt(at(5));
        neighbours = e.GetNeighbours();
        assert(isequal(neighbours{5}, [4 6]), 'A second click removes it; clicking the chosen antenna changes nothing.');
        e.SetEditMode(false);
        list = e.AntennaList;
        set(list, 'Value', 21); callback = get(list, 'Callback'); callback(list, []);
        apply = findobj(fig, 'Style', 'pushbutton', 'String', 'Apply to chosen antenna');
        methods = findobj(fig, 'Style', 'popupmenu', '-and', '-function', @(h) any(strcmp(get(h, 'String'), 'k nearest antennas')));
        set(methods, 'Value', find(strcmp(get(methods, 'String'), 'k nearest antennas')));
        callback = get(methods, 'Callback'); callback(methods, []);
        k = findobj(fig, 'Style', 'edit', 'String', '2');
        set(k, 'String', '3');
        callback = get(apply, 'Callback'); callback(apply, []);
        neighbours = e.GetNeighbours();
        assert(numel(neighbours{21}) == 3 && numel(neighbours{1}) == 2, 'The Apply button changes the chosen antenna only.');
        channels = e.ChannelList;
        set(channels, 'Value', channel(1,3)); callback = get(channels, 'Callback'); callback(channels, []);
        assert(~isempty(strfind(get(e.Status, 'String'), '1-2 1-4'))); %#ok<STREMP>
    end

    function invalidInputs()
        before = findall(0, 'Type', 'figure');
        expectError(@() artefact.neighbourhoodEditor(locations(:, 1), pairs, 'Visible', 'off'), 'artefact:neighbourhoodEditor:Locations');
        expectError(@() artefact.neighbourhoodEditor(locations, [1 30], 'Visible', 'off'), 'artefact:neighbourhoodEditor:ChannelPairs');
        expectError(@() artefact.neighbourhoodEditor(locations, pairs, 'InitialNeighbours', {1}, 'Visible', 'off'), 'artefact:neighbourhoodEditor:InitialNeighbours');
        expectError(@() artefact.neighbourhoodEditor(locations, pairs, 'Rule', 'both', 'Visible', 'off'), 'artefact:referenceChannels:Rule');
        expectError(@() artefact.neighbourhoodEditor(locations, pairs, 'CoordinateUnits', 'in', 'Visible', 'off'), 'artefact:neighbourhoodEditor:CoordinateUnits');
        expectError(@() artefact.neighbourhoodEditor(locations, pairs, 'Wait', true, 'Visible', 'off'), 'artefact:neighbourhoodEditor:Wait');
        assert(isequal(findall(0, 'Type', 'figure'), before), 'No figure is created for invalid inputs.');
    end

    function figuresAndClosing()
        other = figure('Visible', 'off'); plot(1:3);
        [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
        e.SetNeighbours(2, [1 3 4]);
        delete(fig);
        e.SetNeighbours(3, [2 4 5]);
        neighbours = e.GetNeighbours();
        assert(isequal(neighbours{2}, [1 3 4]) && isequal(neighbours{3}, [2 4 5]), 'The editor works after closing.');
        assert(isgraphics(other) && numel(get(get(other, 'CurrentAxes'), 'Children')) == 1);
        delete(other);
    end

    function meritPreview()
        [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'DisplayCoordinateUnits', 'mm', 'Visible', 'off');
        set(fig, 'Position', [0.05 0.05 0.9 0.85]);
        e.ChooseAntenna(1);
        print(fig, fullfile(outputDir, 'neighbourhood_antenna.png'), '-dpng', '-r80');
        e.ChooseChannel(channel(1,3));
        print(fig, fullfile(outputDir, 'neighbourhood_channel.png'), '-dpng', '-r80');
    end

    function averageSubtraction()
        s = [1 2 3 10; 2 4 6 20] + 1i * [0 1 0 1; 1 0 1 0];
        refs = {[2 3]; 1; []; [1 2 3]};
        expected = s;
        expected(:, 1) = s(:, 1) - mean(s(:, [2 3]), 2);
        expected(:, 2) = s(:, 2) - s(:, 1);
        expected(:, 4) = s(:, 4) - mean(s(:, 1:3), 2);
        [out, info] = artefact.subtractAverage(s, refs);
        assert(max(abs(out(:) - expected(:))) < 1e-12, 'Each channel minus the mean of its reference channels.');
        assert(isequal(info.NoReference, 3) && isequal(out(:, 3), s(:, 3)), 'A channel without references is kept.');
        out = artefact.subtractAverage(s, refs, 'Empty', 'zero');
        assert(all(out(:, 3) == 0));
        out = artefact.subtractAverage(cat(3, s, 2 * s), refs);
        assert(max(abs(reshape(out(:, :, 2) - 2 * expected, [], 1))) < 1e-12, 'Further dimensions are processed alike.');
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
        same = repmat((1:5)', 1, size(pairs, 1));
        out = artefact.subtractAverage(same, e.GetResult());
        assert(all(out(:) == 0), 'Identical channels cancel; the editor result is accepted.');
        expectError(@() artefact.subtractAverage(s, refs(1:3)), 'artefact:subtractAverage:References');
        expectError(@() artefact.subtractAverage(s, {5; 1; 1; 1}), 'artefact:subtractAverage:References');
        expectError(@() artefact.subtractAverage(s, refs, 'Empty', 'drop'), 'artefact:subtractAverage:Empty');
        assert(isequal(size(n), [24 1]));
    end

    function expectError(fn, id)
        try
            fn();
        catch problem
            assert(strcmp(problem.identifier, id), 'Expected %s but received %s: %s', id, problem.identifier, problem.message);
            return;
        end
        error('verification:NoError', 'Expected error %s.', id);
    end
end
