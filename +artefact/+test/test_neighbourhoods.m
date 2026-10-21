classdef test_neighbourhoods < matlab.unittest.TestCase
    %TEST_NEIGHBOURHOODS Unit tests of antenna neighbourhoods, reference channels, the neighbourhood editor and average subtraction.
    %   Uses the Galway phantom data supplied with MERIT, found through
    %   merit.process.delay on the MATLAB path. Figures are invisible.
    %   Run with runtests('artefact.test').

    properties
        DataRoot
        OutputDir
        Locations
        Pairs
    end

    methods (TestClassSetup)
        function loadData(testCase)
            testCase.DataRoot = meritDataRoot();
            testCase.assertNotEmpty(testCase.DataRoot, 'Add the MERIT folder to the MATLAB path before running these tests.');
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.OutputDir = folder.Folder;
            testCase.Locations = dlmread(fullfile(testCase.DataRoot, 'antenna_locations.csv'));
            testCase.Pairs = dlmread(fullfile(testCase.DataRoot, 'channel_names.csv'));
        end
    end

    methods (TestMethodSetup)
        function closeNewFigures(testCase)
            before = findall(0, 'Type', 'figure');
            testCase.addTeardown(@() delete(setdiff(findall(0, 'Type', 'figure'), before)));
        end
    end

    methods (Test)
        function nearest(testCase)
            % K nearest neighbours.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            testCase.verifyTrue(isequal(size(n), [24 1]) && all(cellfun(@numel, n) == 2));
            testCase.verifyTrue(isequal(n{1}, [2 10]), 'Adjacent antennas in ring 1, equal distances ordered by number.');
            testCase.verifyTrue(isequal(n{3}, [2 4]));
            testCase.verifyTrue(isequal(n{10}, [1 9]) && isequal(n{21}, [22 24]));
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 0);
            testCase.verifyTrue(all(cellfun(@isempty, n)));
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 30);
            testCase.verifyTrue(numel(n{1}) == 9 && numel(n{21}) == 3, 'K beyond the candidates gives all candidates.');
            square = [0 0 0; 1 0 0; 0 1 0; 1 1 0];
            n = artefact.antennaNeighbours(square, [], 'nearest', 'K', 1, 'MeasuredOnly', false);
            testCase.verifyTrue(isequal(n{1}, 2) && isequal(n{4}, 2), 'Ties are broken by the lower antenna number.');
        end

        function withinDistance(testCase)
            % Neighbours within a distance.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.045);
            testCase.verifyTrue(isequal(n{1}, [2 10]));
            n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.09);
            testCase.verifyTrue(isequal(n{1}, [2 3 9 10]), 'Within 90 mm: antennas one and two places apart.');
            n = artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0);
            testCase.verifyTrue(all(cellfun(@isempty, n)));
            n = artefact.antennaNeighbours(locations, pairs);
            testCase.verifyTrue(isequal(n, artefact.antennaNeighbours(locations, pairs, 'distance')), 'The default method is distance.');
            testCase.verifyTrue(isequal(n, artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2)), ...
                'The default distance gives every Galway antenna its two adjacent antennas, including ring 3.');
            testCase.verifyTrue(isequal(artefact.antennaNeighbours(locations, pairs, 'Distance', 0.09), ...
                artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', 0.09)), 'Distance without a method.');
            [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            result = e.GetResult();
            delete(fig);
            testCase.verifyTrue(isequal(result.Neighbours, n), 'The editor starts with the default distance.');
        end

        function candidates(testCase)
            % Candidate restriction and subsets.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2, 'MeasuredOnly', false);
            testCase.verifyTrue(isequal(n{1}, [11 20]), 'Without the restriction, antennas 11 and 20 in ring 2 are nearest (34 mm).');
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2, 'Antennas', [1 5]);
            testCase.verifyTrue(~isempty(n{1}) && ~isempty(n{5}) && all(cellfun(@isempty, n([2:4 6:24]))));
            n = artefact.antennaNeighbours(locations, [1 2; 2 3], 'nearest', 'K', 5);
            testCase.verifyTrue(isequal(n{1}, 2) && isequal(n{2}, [1 3]) && isempty(n{4}), 'Only antennas with a measured channel are candidates.');
            testCase.verifyError(@() artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', -1), 'artefact:antennaNeighbours:K');
            testCase.verifyError(@() artefact.antennaNeighbours(locations, pairs, 'distance', 'Distance', -1), 'artefact:antennaNeighbours:Distance');
            testCase.verifyError(@() artefact.antennaNeighbours(locations, pairs, 'kmeans', 'K', 2), 'artefact:antennaNeighbours:Method');
            testCase.verifyError(@() artefact.antennaNeighbours(locations, [1 30], 'nearest', 'K', 2), 'artefact:antennaNeighbours:ChannelPairs');
        end

        function rules(testCase)
            % Receiver and transmitter rules.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            r = artefact.referenceChannels(n, pairs);
            testCase.verifyTrue(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,4)])), 'Receiver rule for 1-3: 1-2 and 1-4.');
            r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
            testCase.verifyTrue(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,10)])), 'Transmitter rule for 1-3: 1-2 and 1-10.');
            r = artefact.referenceChannels(n, pairs, 'IncludeSelf', true);
            testCase.verifyTrue(isequal(r{channel(1,3)}, sort([channel(1,2) channel(1,3) channel(1,4)])));
            r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
            testCase.verifyTrue(isequal(r{channel(1,2)}, channel(1,10)), 'The channel itself (1-2) is left out of its reference.');
            testCase.verifyError(@() artefact.referenceChannels(n, pairs, 'Rule', 'both'), 'artefact:referenceChannels:Rule');
            bad = n; bad{1} = [1 2];
            testCase.verifyError(@() artefact.referenceChannels(bad, pairs), 'artefact:referenceChannels:Neighbours');
        end

        function reciprocity(testCase)
            % Reciprocity, missing channels and monostatic data.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            [r, info] = artefact.referenceChannels(n, pairs);
            testCase.verifyTrue(isequal(r{channel(9,10)}, channel(1,9)), ...
                'Receiver rule for 9-10: neighbours of 10 are 1 and 9; 9 is the transmitter, and 9-1 is measured as 1-9.');
            testCase.verifyTrue(isempty(info.NoReference));
            r = artefact.referenceChannels(n, pairs, 'Rule', 'transmitter');
            testCase.verifyTrue(isequal(r{channel(9,10)}, channel(8,9)), 'Transmitter rule for 9-10: 9-8 is measured as 8-9.');
            hand = n; hand{1} = 11;
            [r, info] = artefact.referenceChannels(hand, pairs, 'Rule', 'transmitter');
            c = channel(1,2);
            testCase.verifyTrue(isempty(r{c}) && isequal(info.Missing{c}, [1 11]) && any(info.NoReference == c), ...
                'An unmeasured reference channel is omitted and reported.');
            line = [0 0 0; 1 0 0; 2 0 0; 3 0 0];
            mono = [1 1; 2 2; 3 3; 4 4];
            nm = artefact.antennaNeighbours(line, mono, 'nearest', 'K', 2);
            testCase.verifyTrue(isequal(nm{1}, [2 3]) && isequal(nm{3}, [2 4]));
            rm = artefact.referenceChannels(nm, mono);
            testCase.verifyTrue(isequal(rm{1}, [2 3]) && isequal(rm{3}, [2 4]), 'Monostatic: the neighbours'' own channels.');
            rm = artefact.referenceChannels(nm, mono, 'Rule', 'transmitter');
            testCase.verifyTrue(isequal(rm{1}, [2 3]), 'Both rules agree for monostatic channels.');
        end

        function editorOperations(testCase)
            % Editor operations.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            outputDir = testCase.OutputDir;
            [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            testCase.verifyTrue(isequal(e.GetNeighbours(), n), 'The editor starts from the two nearest antennas.');
            testCase.verifyTrue(isequal(e.GetReferences(), artefact.referenceChannels(n, pairs)));
            e.SetNeighbours(1, [2 3 10]);
            neighbours = e.GetNeighbours();
            testCase.verifyTrue(isequal(neighbours{1}, [2 3 10]) && isequal(neighbours(2:end), n(2:end)), 'Only antenna 1 changes.');
            e.ApplyMethod('distance', 'Distance', 0.09, 'Antennas', 21);
            neighbours = e.GetNeighbours();
            testCase.verifyTrue(isequal(neighbours{21}, [22 23 24]) && isequal(neighbours{1}, [2 3 10]));
            e.SetReferenceOptions('Rule', 'transmitter', 'IncludeSelf', true);
            result = e.GetResult();
            testCase.verifyTrue(strcmp(result.Rule, 'transmitter') && result.IncludeSelf);
            testCase.verifyTrue(isequal(result.References, artefact.referenceChannels(result.Neighbours, pairs, 'Rule', 'transmitter', 'IncludeSelf', true)));
            testCase.verifyError(@() e.SetNeighbours(1, 1), 'artefact:neighbourhoodEditor:Neighbours');
            testCase.verifyError(@() e.SetReferenceOptions('Rule', 'both'), 'artefact:referenceChannels:Rule');
            result = e.GetResult();
            testCase.verifyTrue(numel(result.History) == 3, 'Failed operations are not recorded.');
            file = fullfile(outputDir, 'neighbourhoods.mat');
            e.Save(file);
            loaded = load(file);
            testCase.verifyTrue(isequal(loaded.neighbourhoods.Neighbours, result.Neighbours));
        end

        function editorClicks(testCase)
            % Editor clicks and callbacks.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            [fig, e] = artefact.neighbourhoodEditor(locations * 1000, pairs, 'CoordinateUnits', 'mm', 'Visible', 'off');
            at = @(a) [locations(a, 1:2) * 1000 500; locations(a, 1:2) * 1000 -500];
            e.ClickAt(at(5));
            state = e.GetResult();
            testCase.verifyTrue(isequal(state.Neighbours{5}, [4 6]));
            e.SetEditMode(true);
            e.ClickAt(at(8));
            neighbours = e.GetNeighbours();
            testCase.verifyTrue(isequal(neighbours{5}, [4 6 8]), 'In edit mode a click adds the antenna to the chosen neighbourhood.');
            e.ClickAt(at(8));
            e.ClickAt(at(5));
            neighbours = e.GetNeighbours();
            testCase.verifyTrue(isequal(neighbours{5}, [4 6]), 'A second click removes it; clicking the chosen antenna changes nothing.');
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
            testCase.verifyTrue(numel(neighbours{21}) == 3 && numel(neighbours{1}) == 2, 'The Apply button changes the chosen antenna only.');
            channels = e.ChannelList;
            set(channels, 'Value', channel(1,3)); callback = get(channels, 'Callback'); callback(channels, []);
            testCase.verifyTrue(~isempty(strfind(get(e.Status, 'String'), '1-2 1-4'))); %#ok<STREMP>
        end

        function invalidInputs(testCase)
            % Invalid inputs precede graphics.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            before = findall(0, 'Type', 'figure');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations(:, 1), pairs, 'Visible', 'off'), 'artefact:neighbourhoodEditor:Locations');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, [1 30], 'Visible', 'off'), 'artefact:neighbourhoodEditor:ChannelPairs');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, pairs, 'InitialNeighbours', {1}, 'Visible', 'off'), 'artefact:neighbourhoodEditor:InitialNeighbours');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, pairs, 'Rule', 'both', 'Visible', 'off'), 'artefact:referenceChannels:Rule');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, pairs, 'CoordinateUnits', 'in', 'Visible', 'off'), 'artefact:neighbourhoodEditor:CoordinateUnits');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, pairs, 'Wait', true, 'Visible', 'off'), 'artefact:neighbourhoodEditor:Wait');
            testCase.verifyTrue(isequal(findall(0, 'Type', 'figure'), before), 'No figure is created for invalid inputs.');
        end

        function imagingDomain(testCase)
            % Imaging domain drawn as a transparent surface.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            [x, y, z] = ndgrid(-0.06:0.01:0.06, -0.06:0.01:0.06, 0:0.01:0.06);
            inside = x.^2 + y.^2 + z.^2 <= 0.06^2;
            points = [x(inside) y(inside) z(inside)];
            [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'ImagingDomain', points, 'Visible', 'off');
            testCase.verifyTrue(isgraphics(e.DomainSurface) && strcmp(get(e.DomainSurface, 'Visible'), 'on'), 'The domain surface is drawn.');
            testCase.verifyTrue(strcmp(get(e.DomainSurface, 'HitTest'), 'off'), 'The surface does not take clicks.');
            vertices = get(e.DomainSurface, 'Vertices');
            testCase.verifyTrue(all(ismember(vertices, points, 'rows')), 'The surface vertices are imaging points.');
            set(e.DomainCheck, 'Value', 0); callback = get(e.DomainCheck, 'Callback'); callback(e.DomainCheck, []);
            testCase.verifyTrue(strcmp(get(e.DomainSurface, 'Visible'), 'off'), 'The checkbox hides the surface.');
            e.ChooseAntenna(5);
            testCase.verifyTrue(isequal(e.GetNeighbours(), artefact.antennaNeighbours(locations, pairs)), 'The domain does not change the neighbourhoods.');
            delete(fig);
            [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'ImagingDomain', [0 0; 0.05 0; 0 0.05; 0.05 0.05], 'Visible', 'off');
            testCase.verifyTrue(isgraphics(e.DomainSurface), 'A flat domain is drawn as an outline.');
            [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            testCase.verifyTrue(isempty(e.DomainSurface) && isempty(e.DomainCheck), 'Without a domain there is no surface or checkbox.');
            before = findall(0, 'Type', 'figure');
            testCase.verifyError(@() artefact.neighbourhoodEditor(locations, pairs, 'ImagingDomain', [1 2 3 4], 'Visible', 'off'), ...
                'artefact:neighbourhoodEditor:ImagingDomain');
            testCase.verifyTrue(isequal(findall(0, 'Type', 'figure'), before), 'No figure is created for an invalid domain.');
        end

        function figuresAndClosing(testCase)
            % Unrelated figures and closing.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            other = figure('Visible', 'off'); plot(1:3);
            [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            e.SetNeighbours(2, [1 3 4]);
            delete(fig);
            e.SetNeighbours(3, [2 4 5]);
            neighbours = e.GetNeighbours();
            testCase.verifyTrue(isequal(neighbours{2}, [1 3 4]) && isequal(neighbours{3}, [2 4 5]), 'The editor works after closing.');
            testCase.verifyTrue(isgraphics(other) && numel(get(get(other, 'CurrentAxes'), 'Children')) == 1);
            delete(other);
        end

        function meritPreview(testCase)
            % MERIT data and preview.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            outputDir = testCase.OutputDir;
            [fig, e] = artefact.neighbourhoodEditor(locations, pairs, 'DisplayCoordinateUnits', 'mm', 'Visible', 'off');
            set(fig, 'Position', [0.05 0.05 0.9 0.85]);
            e.ChooseAntenna(1);
            print(fig, fullfile(outputDir, 'neighbourhood_antenna.png'), '-dpng', '-r80');
            e.ChooseChannel(channel(1,3));
            print(fig, fullfile(outputDir, 'neighbourhood_channel.png'), '-dpng', '-r80');
        end

        function averageSubtraction(testCase)
            % Average subtraction.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            channel = @(tx, rx) find(pairs(:,1) == tx & pairs(:,2) == rx);
            s = [1 2 3 10; 2 4 6 20] + 1i * [0 1 0 1; 1 0 1 0];
            refs = {[2 3]; 1; []; [1 2 3]};
            expected = s;
            expected(:, 1) = s(:, 1) - mean(s(:, [2 3]), 2);
            expected(:, 2) = s(:, 2) - s(:, 1);
            expected(:, 4) = s(:, 4) - mean(s(:, 1:3), 2);
            [out, info] = artefact.subtractAverage(s, refs);
            testCase.verifyTrue(max(abs(out(:) - expected(:))) < 1e-12, 'Each channel minus the mean of its reference channels.');
            testCase.verifyTrue(isequal(info.NoReference, 3) && isequal(out(:, 3), s(:, 3)), 'A channel without references is kept.');
            out = artefact.subtractAverage(s, refs, 'Empty', 'zero');
            testCase.verifyTrue(all(out(:, 3) == 0));
            out = artefact.subtractAverage(cat(3, s, 2 * s), refs);
            testCase.verifyTrue(max(abs(reshape(out(:, :, 2) - 2 * expected, [], 1))) < 1e-12, 'Further dimensions are processed alike.');
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            [~, e] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            same = repmat((1:5)', 1, size(pairs, 1));
            out = artefact.subtractAverage(same, e.GetResult());
            testCase.verifyTrue(all(out(:) == 0), 'Identical channels cancel; the editor result is accepted.');
            testCase.verifyError(@() artefact.subtractAverage(s, refs(1:3)), 'artefact:subtractAverage:References');
            testCase.verifyError(@() artefact.subtractAverage(s, {5; 1; 1; 1}), 'artefact:subtractAverage:References');
            testCase.verifyError(@() artefact.subtractAverage(s, refs, 'Empty', 'drop'), 'artefact:subtractAverage:Empty');
            testCase.verifyTrue(isequal(size(n), [24 1]));
        end
    end
end

function dataRoot = meritDataRoot()
% Folder of MERIT's Galway example data: data in the 2019 snapshot, example_data in version 1.0 and later.
dataRoot = '';
delayFile = which('merit.process.delay');
if isempty(delayFile), return; end
meritRoot = fileparts(fileparts(fileparts(delayFile)));
for name = {'data', 'example_data'}
    if exist(fullfile(meritRoot, name{1}, 'antenna_locations.csv'), 'file')
        dataRoot = fullfile(meritRoot, name{1});
        return;
    end
end
end
