function results = verify_signal_viewer(projectRoot, outputDir)
%VERIFY_SIGNAL_VIEWER Scripted checks of signalvis.signalViewer.
%   Figures are invisible. Selections are made through the returned viewer
%   functions and through the table callbacks with simulated edit events.
%   Displayed values are compared with GetDisplayedData and with the plotted
%   line data. Uses MERIT's example data, found through MERIT on the path.
if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2, outputDir = tempname; end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
fprintf('Signal viewer verification output: %s\n', outputDir);
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));
addpath(projectRoot);
delayFile = which('merit.process.delay');
assert(~isempty(delayFile), 'verification:MERITMissing', ...
    'Add the MERIT folder to the MATLAB path before running this check.');
dataRoot = fullfile(fileparts(fileparts(fileparts(delayFile))), 'data');
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));

names = {'complex quantities', 'real waveforms', 'magnitude input and dB conversion', ...
    'phase input, units and unwrapping', 'sample axis units', 'Tx and Rx selection', ...
    'channel list and table callbacks', 'channel with its reference channels', 'several datasets', ...
    'individual layout and paging', 'invalid inputs precede graphics', ...
    'unrelated figures and closing', 'MERIT data and previews'};
cases = {@complexQuantities, @waveforms, @magnitudeInput, @phaseInput, @axisUnits, ...
    @txRxSelection, @channelList, @referenceView, @datasets, @paging, @invalidInputs, ...
    @figuresAndClosing, @meritPreviews};
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
assert(all([results.passed]), 'verification:Failed', 'Signal viewer verification failed.');

    function complexQuantities()
        s = [1+2i, 3-4i; -2+1i, -1-3i; 2-2i, 1+1i];
        [~, v] = signalvis.signalViewer(s, [], [], 'Visible', 'off');
        state = v.GetSelection();
        assert(strcmp(state.Quantity, 'both'), 'Complex input shows magnitude and phase by default.');
        lines = v.GetDisplayedData();
        assert(numel(lines) == 4 && numel(plotted(v)) == 4);
        assert(numel(findobj(v.PlotPanel, 'Type', 'axes')) == 2);
        checkLine(lines, 'magnitude', 1, 1, abs(s(:,1)));
        checkLine(lines, 'phase', 1, 2, angle(s(:,2)));
        v.SetDisplay('Quantity', 'real'); checkLine(v.GetDisplayedData(), 'real', 1, 2, real(s(:,2)));
        v.SetDisplay('Quantity', 'imaginary'); checkLine(v.GetDisplayedData(), 'imaginary', 1, 1, imag(s(:,1)));
        expectError(@() v.SetDisplay('Quantity', 'value'), 'signalvis:signalViewer:Quantity');
        [~, v] = signalvis.signalViewer(real(s), [], [], 'InputType', 'complex', 'Quantity', 'both', 'Visible', 'off');
        assert(numel(v.GetDisplayedData()) == 4, 'An explicitly complex real-valued spectrum has phase.');
        [~, v] = signalvis.signalViewer([1+1i; complex(Inf,1); 1-1i], [], [], 'Quantity', 'phase', 'Visible', 'off');
        y = v.GetDisplayedData(); y = y(1).Y;
        assert(~isfinite(y(2)) && isfinite(y(3)), 'Non-finite complex samples stay local gaps.');
    end

    function waveforms()
        w = [-2 1; 1 0; 3 -4];
        [~, v] = signalvis.signalViewer(w, [], [], 'Visible', 'off');
        lines = v.GetDisplayedData();
        assert(strcmp(selectionField(v, 'Quantity'), 'value'));
        checkLine(lines, 'value', 1, 1, w(:,1)); checkLine(lines, 'value', 1, 2, w(:,2));
        closeEnough(lines(1).X, [1;2;3]);
        v.SetDisplay('Quantity', 'magnitude'); checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [2;1;3]);
        expectError(@() v.SetDisplay('Quantity', 'phase'), 'signalvis:signalViewer:Quantity');
        offered = get(v.QuantityPopup, 'String');
        assert(isequal(sort(offered(:))', sort({'Magnitude', 'Value'})), 'Only valid quantities are offered.');
    end

    function magnitudeInput()
        values = [-65 -30; -20 -5; -3 2];
        [~, v] = signalvis.signalViewer(values, [], [], 'InputType', 'magnitude', 'InputMagnitudeScale', 'dB', 'Visible', 'off');
        lines = v.GetDisplayedData();
        checkLine(lines, 'magnitude', 1, 1, values(:,1)); checkLine(lines, 'magnitude', 1, 2, values(:,2));
        assert(strcmp(lines(1).QuantityLabel, 'Magnitude (dB)'), 'dB input is displayed in dB by default.');
        v.SetDisplay('MagnitudeScale', 'linear');
        checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, 10.^(values(:,1)/20));
        [~, v] = signalvis.signalViewer([-40; 0; 20], [], [], 'InputType', 'magnitude', 'InputMagnitudeScale', 'dB', ...
            'MagnitudeScale', 'linear', 'Visible', 'off');
        checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [.01; 1; 10]);
        [~, v] = signalvis.signalViewer([0; .01; 1; NaN; Inf], [], [], 'InputType', 'magnitude', ...
            'MagnitudeScale', 'dB', 'Visible', 'off');
        checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [-Inf; -40; 0; NaN; Inf]);
        offered = get(v.QuantityPopup, 'String');
        assert(isequal(offered(:)', {'Magnitude'}), 'Magnitude input offers magnitude only.');
        expectError(@() signalvis.signalViewer([1; -1], [], [], 'InputType', 'magnitude', 'Visible', 'off'), ...
            'signalvis:signalViewer:InputMagnitudeScale');
    end

    function phaseInput()
        p = [170; 190; NaN; 530; 550];
        [~, v] = signalvis.signalViewer(p, [], [], 'InputType', 'phase', 'InputPhaseUnits', 'degrees', 'Visible', 'off');
        checkLine(v.GetDisplayedData(), 'phase', 1, 1, p);
        v.SetDisplay('PhaseUnits', 'radians');
        checkLine(v.GetDisplayedData(), 'phase', 1, 1, p*pi/180);
        [~, v] = signalvis.signalViewer([170; -170; NaN; 170; -170], [], [], 'InputType', 'phase', ...
            'InputPhaseUnits', 'degrees', 'UnwrapPhase', true, 'Visible', 'off');
        checkLine(v.GetDisplayedData(), 'phase', 1, 1, [170; 190; NaN; 170; 190]);
        expectError(@() v.SetDisplay('Quantity', 'magnitude'), 'signalvis:signalViewer:Quantity');
        s = exp(1i * (0:0.9:9)');
        [~, v] = signalvis.signalViewer(s, [], [], 'Quantity', 'phase', 'UnwrapPhase', true, 'Visible', 'off');
        checkLine(v.GetDisplayedData(), 'phase', 1, 1, unwrap(angle(s)));
    end

    function axisUnits()
        [~, v] = signalvis.signalViewer([1; 2; 3], [1e9 2e9 3e9], [], 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Visible', 'off');
        lines = v.GetDisplayedData(); closeEnough(lines(1).X, [1; 2; 3]);
        ax = findobj(v.PlotPanel, 'Type', 'axes');
        assert(strcmp(get(get(ax(1), 'XLabel'), 'String'), 'Frequency (GHz)'));
        [~, v] = signalvis.signalViewer([1; 2], [1; 2], [], 'AxisUnits', 'ns', 'DisplayAxisUnits', 's', 'Visible', 'off');
        lines = v.GetDisplayedData(); closeEnough(lines(1).X, [1e-9; 2e-9]);
        expectError(@() signalvis.signalViewer([1; 2], [1; 2], [], 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'ns', 'Visible', 'off'), ...
            'signalvis:signalViewer:DisplayAxisUnits');
    end

    function txRxSelection()
        [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
        state = v.GetSelection();
        % Each ring lists pairs with the lower antenna as Tx: 10, 20 and 24 never transmit; 1, 11 and 21 never receive.
        assert(isequal(state.Channels, 1:96) && isequal(state.Tx, setdiff(1:24, [10 20 24])) && isequal(state.Rx, setdiff(1:24, [1 11 21])));
        v.SelectTx(5);
        state = v.GetSelection();
        assert(isequal(state.Channels, find(pairs(:,1) == 5)'), 'Tx 5 with all Rx shows the channels transmitted by 5.');
        assert(all(strncmp(state.ChannelLabels, '5-', 2)));
        v.SelectTx(unique(pairs(:,1))); v.SelectRx(5);
        state = v.GetSelection();
        assert(isequal(state.Channels, find(pairs(:,2) == 5)'), 'Strict matching: Rx 5 shows channels received by 5.');
        v.SelectTx([1 2]); v.SelectRx([3 4]);
        expected = find(ismember(pairs(:,1), [1 2]) & ismember(pairs(:,2), [3 4]))';
        state = v.GetSelection();
        assert(isequal(state.Channels, expected) && numel(expected) == 4);
        tablesAgree(v);
        lines = v.GetDisplayedData();
        assert(isequal(unique([lines.Channel]), expected));
        assert(numel(plotted(v)) == numel(lines));
        v.SelectRx([]);
        assert(isempty(selectionField(v, 'Channels')) && isempty(v.GetDisplayedData()));
        expectError(@() v.SelectTx(10), 'signalvis:signalViewer:Tx');
        expectError(@() v.SelectRx(11), 'signalvis:signalViewer:Rx');
    end

    function channelList()
        [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
        allTx = unique(pairs(:,1))'; allRx = unique(pairs(:,2))';
        tablesAgree(v);
        % Channel ticks change only the channels; the Tx and Rx ticks stay as they are.
        v.SelectChannels([3 1 7]);
        state = v.GetSelection();
        assert(isequal(state.Channels, [1 3 7]));
        assert(isequal(state.Tx, allTx) && isequal(state.Rx, allRx), 'Channel ticks leave the Tx and Rx ticks unchanged.');
        tablesAgree(v);
        editCell(v.ChannelTable, 3, 2, false);
        state = v.GetSelection();
        assert(isequal(state.Channels, [1 7]), 'Unticking a channel hides only that channel.');
        assert(isequal(state.Tx, allTx) && isequal(state.Rx, allRx));
        tablesAgree(v);
        editCell(v.ChannelTable, 50, 2, true);
        assert(isequal(selectionField(v, 'Channels'), [1 7 50]));
        tablesAgree(v);
        data = get(v.ChannelTable, 'Data');
        assert(strcmp(data{1, 1}, '1-2') && data{1, 2} == true && data{2, 2} == false);
        % Tx and Rx ticks to channel ticks.
        v.SelectTx(allTx); v.SelectRx(allRx);
        editCell(v.TxTable, 1, 2, false);
        state = v.GetSelection();
        assert(~any(state.Tx == 1) && isequal(state.Channels, find(pairs(:,1) ~= 1)'), ...
            'A Tx table edit recomputes the channel ticks.');
        tablesAgree(v);
        v.SelectRx([]); editCell(v.RxTable, 1, 2, true);
        state = v.GetSelection();
        assert(isequal(state.Rx, 2) && isempty(state.Channels), 'Tx 1 is unticked, so Rx 2 alone matches nothing.');
        tablesAgree(v);
        v.SelectChannels([]);
        state = v.GetSelection();
        assert(isempty(state.Channels) && isequal(state.Rx, 2), 'Clearing the channels leaves the Tx and Rx ticks unchanged.');
        tablesAgree(v);
        v.SelectChannels(1:96);
        state = v.GetSelection();
        assert(numel(state.Channels) == 96 && isequal(state.Rx, 2));
        tablesAgree(v);
    end

    function editCell(table, row, column, value)
        % As a click does: change the cell, then call the edit callback.
        data = get(table, 'Data'); data{row, column} = value; set(table, 'Data', data);
        callback = get(table, 'CellEditCallback');
        callback(table, struct('Indices', [row column], 'NewData', value));
    end

    function tablesAgree(v)
        % The ticks shown in the tables equal the viewer's selection.
        state = v.GetSelection();
        data = get(v.ChannelTable, 'Data');
        assert(isequal(find([data{:, 2}]), state.Channels), 'Channel table ticks differ from the selection.');
        data = get(v.TxTable, 'Data');
        assert(isequal(cellfun(@str2double, data([data{:, 2}], 1))', state.Tx), 'Tx table ticks differ from the selection.');
        data = get(v.RxTable, 'Data');
        assert(isequal(cellfun(@str2double, data([data{:, 2}], 1))', state.Rx), 'Rx table ticks differ from the selection.');
    end

    function referenceView()
        n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
        refs = artefact.referenceChannels(n, pairs);
        [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'References', refs, 'Visible', 'off');
        c = find(pairs(:,1) == 1 & pairs(:,2) == 3);
        v.ShowReference(c);
        state = v.GetSelection();
        assert(isequal(state.Channels, sort([c refs{c}])) && state.ReferenceFor == c, ...
            'The channel and its reference channels are shown.');
        assert(isequal(state.ChannelLabels, {'1-2', '1-3', '1-4'}), 'Receiver rule: channel 1-3 has the reference 1-2 and 1-4.');
        tablesAgree(v);
        lines = v.GetDisplayedData();
        assert(all([lines([lines.Channel] == c).Highlighted]) && ~any([lines([lines.Channel] ~= c).Highlighted]));
        drawn = plotted(v);
        widths = cell2mat(get(drawn, 'LineWidth'));
        drawnNames = get(drawn, 'DisplayName');
        assert(all(strcmp(drawnNames(widths > 1), '1-3')) && any(widths > 1), 'Only the chosen channel is drawn thick.');
        set(v.ReferencePopup, 'Value', 2);
        callback = get(v.ReferencePopup, 'Callback'); callback(v.ReferencePopup, []);
        assert(selectionField(v, 'ReferenceFor') == 1, 'The popup chooses the channel.');
        v.SelectTx(1);
        assert(selectionField(v, 'ReferenceFor') == 0, 'A Tx selection clears the chosen channel.');
        [~, editor] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
        [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'References', editor.GetResult(), 'Visible', 'off');
        v.ShowReference(c);
        assert(isequal(selectionField(v, 'Channels'), sort([c refs{c}])), 'The editor result is accepted.');
        expectError(@() v.ShowReference(97), 'signalvis:signalViewer:Channel');
        [~, w] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
        expectError(@() w.ShowReference(1), 'signalvis:signalViewer:References');
    end

    function datasets()
        subtracted = scan1 - scan2;
        [~, v] = signalvis.signalViewer({scan1, scan2, subtracted}, frequencies, pairs, ...
            'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, 'InitialTx', 1, 'InitialRx', [2 3], ...
            'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Quantity', 'magnitude', 'Visible', 'off');
        lines = v.GetDisplayedData();
        assert(numel(lines) == 6);
        checkLine(lines, 'magnitude', 3, 10, abs(subtracted(:,10)));
        drawn = plotted(v);
        assert(numel(drawn) == 6);
        for k = 1:numel(drawn)
            name = get(drawn(k), 'DisplayName');
            match = drawn(strcmp(get(drawn, 'DisplayName'), strrep(name, '(Original)', '(Rotated)')));
            if ~isempty(strfind(name, '(Original)')) %#ok<STREMP>
                assert(isequal(get(drawn(k), 'Color'), get(match, 'Color')), 'A channel keeps its colour in every dataset.');
                assert(~strcmp(get(drawn(k), 'LineStyle'), get(match, 'LineStyle')), 'Datasets differ in line style.');
            end
        end
        v.SelectDatasets([2 3]);
        drawn = plotted(v);
        styles = get(drawn, 'LineStyle'); labels = get(drawn, 'DisplayName');
        assert(all(strcmp(styles(~cellfun(@isempty, strfind(labels, 'Subtracted'))), ':')), ...
            'A dataset keeps the line style given in the dataset table.');
        v.SelectDatasets([1 3]);
        lines = v.GetDisplayedData();
        assert(isequal(unique([lines.Dataset]), [1 3]));
        editCell(v.DatasetTable, 1, 3, false);
        assert(isequal(selectionField(v, 'Datasets'), 3));
        dB = 20 * log10(abs(scan1));
        [~, v] = signalvis.signalViewer({scan1, dB}, frequencies, pairs, 'InputType', {'complex', 'magnitude'}, ...
            'InputMagnitudeScale', {'linear', 'dB'}, 'InitialTx', 1, 'InitialRx', 2, 'Visible', 'off');
        lines = v.GetDisplayedData();
        assert(sum(strcmp({lines.Quantity}, 'magnitude')) == 2 && sum(strcmp({lines.Quantity}, 'phase')) == 1, ...
            'The magnitude-only dataset contributes to the magnitude axis only.');
        v.SetDisplay('MagnitudeScale', 'db');
        lines = v.GetDisplayedData();
        magnitudes = lines(strcmp({lines.Quantity}, 'magnitude'));
        closeEnough(magnitudes(1).Y, magnitudes(2).Y);
        v.SetDisplay('Quantity', 'phase');
        assert(~isempty(strfind(get(v.Status, 'String'), 'Dataset 2'))); %#ok<STREMP>
    end

    function paging()
        [fig, v] = signalvis.signalViewer({scan1, scan2}, frequencies, pairs, 'Layout', 'individual', ...
            'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Visible', 'off');
        state = v.GetSelection();
        assert(state.Pages == 16 && state.Page == 1);
        lines = v.GetDisplayedData();
        assert(isequal(unique([lines.Channel]), 1:6) && numel(lines) == 6 * 2 * 2);
        assert(numel(findobj(v.PlotPanel, 'Type', 'axes')) == 12);
        next = findobj(fig, 'Style', 'pushbutton', 'String', 'Next');
        callback = get(next, 'Callback'); callback(next, []);
        lines = v.GetDisplayedData();
        assert(selectionField(v, 'Page') == 2 && isequal(unique([lines.Channel]), 7:12));
        v.SetDisplay('Page', 16);
        assert(isequal(unique(displayedField(v, 'Channel')), 91:96));
        v.SelectTx(1);
        state = v.GetSelection();
        assert(state.Page == 1 && state.Pages == 2, 'The page is limited to the new selection.');
        expectError(@() v.SetDisplay('Page', 3), 'signalvis:signalViewer:Page');
        v.SetDisplay('Layout', 'overlay');
        assert(strcmp(get(next, 'Visible'), 'off'));
        % Column widths follow the table width (the resize handler is called
        % directly because invisible figures receive no resize events).
        for size = [1257 660; 2355 1238]'
            set(fig, 'Units', 'pixels', 'Position', [1 1 size']);
            resize = get(fig, 'SizeChangedFcn'); resize(fig, []);
            width = getpixelposition(v.ChannelTable);
            columns = cell2mat(get(v.ChannelTable, 'ColumnWidth'));
            assert(sum(columns) <= width(3) && sum(columns) >= width(3) - 30, ...
                'Channel columns fill the table without exceeding it.');
        end
    end

    function invalidInputs()
        before = findall(0, 'Type', 'figure');
        expectError(@() signalvis.signalViewer({scan1, scan1(1:10,:)}, [], pairs, 'Visible', 'off'), 'signalvis:signalViewer:Signals');
        expectError(@() signalvis.signalViewer(scan1, frequencies(1:5), pairs, 'Visible', 'off'), 'signalvis:signalViewer:SampleAxis');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs(1:5,:), 'Visible', 'off'), 'signalvis:signalViewer:ChannelPairs');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'InputType', 'waveform', 'Visible', 'off'), 'signalvis:signalViewer:InputType');
        expectError(@() signalvis.signalViewer({scan1, scan2}, frequencies, pairs, 'InputType', {'complex'}, 'Visible', 'off'), 'signalvis:signalViewer:InputType');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'Quantity', 'value', 'Visible', 'off'), 'signalvis:signalViewer:Quantity');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'InitialTx', 24, 'Visible', 'off'), 'signalvis:signalViewer:InitialTx');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'References', {1}, 'Visible', 'off'), 'signalvis:signalViewer:References');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'References', repmat({200}, 96, 1), 'Visible', 'off'), 'signalvis:signalViewer:References');
        expectError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'DatasetNames', {'a', 'b'}, 'Visible', 'off'), 'signalvis:signalViewer:DatasetNames');
        assert(isequal(findall(0, 'Type', 'figure'), before), 'No figure is created for invalid inputs.');
    end

    function figuresAndClosing()
        other = figure('Visible', 'off'); plot(1:3);
        [fig, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
        v.SelectTx(2);
        assert(isgraphics(other) && numel(get(get(other, 'CurrentAxes'), 'Children')) == 1);
        delete(fig);
        v.SelectTx(3);
        assert(isequal(selectionField(v, 'Tx'), 3), 'Selections still work after the figure is closed.');
        assert(~isempty(v.GetDisplayedData()));
        delete(other);
    end

    function meritPreviews()
        refs = artefact.referenceChannels(artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2), pairs);
        [fig, v] = signalvis.signalViewer({scan1, scan2, scan1 - scan2}, frequencies, pairs, ...
            'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, 'References', refs, ...
            'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'InitialTx', 1, 'InitialRx', [2 3], 'Visible', 'off');
        set(fig, 'Position', [0.04 0.06 0.92 0.86]);
        print(fig, fullfile(outputDir, 'viewer_overlay.png'), '-dpng', '-r80');
        v.ShowReference(find(pairs(:,1) == 1 & pairs(:,2) == 3));
        print(fig, fullfile(outputDir, 'viewer_reference.png'), '-dpng', '-r80');
        v.SetDisplay('Layout', 'individual', 'MagnitudeScale', 'db');
        print(fig, fullfile(outputDir, 'viewer_individual.png'), '-dpng', '-r80');
    end

    function value = selectionField(v, name)
        state = v.GetSelection(); value = state.(name);
    end

    function values = displayedField(v, name)
        shown = v.GetDisplayedData(); values = [shown.(name)];
    end

    function drawn = plotted(v)
        drawn = findobj(v.PlotPanel, 'Type', 'line');
    end

    function checkLine(lines, quantity, dataset, channel, expected)
        match = lines(strcmp({lines.Quantity}, quantity) & [lines.Dataset] == dataset & [lines.Channel] == channel);
        assert(numel(match) == 1, 'Expected one %s line for dataset %d, channel %d.', quantity, dataset, channel);
        closeEnough(match.Y, expected);
    end

    function closeEnough(actual, expected)
        actual = double(actual(:)); expected = double(expected(:));
        assert(isequal(size(actual), size(expected)), 'Size mismatch.');
        same = (isnan(actual) & isnan(expected)) | (actual == expected) | abs(actual - expected) <= 1e-9 * max(1, abs(expected));
        assert(all(same), 'Values differ: %s against %s.', mat2str(actual', 6), mat2str(expected', 6));
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
