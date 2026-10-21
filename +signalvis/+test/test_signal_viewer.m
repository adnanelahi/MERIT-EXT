classdef test_signal_viewer < matlab.unittest.TestCase
    %TEST_SIGNAL_VIEWER Unit tests of signalvis.signalViewer.
    %   Uses the Galway phantom data supplied with MERIT, found through
    %   merit.process.delay on the MATLAB path. Figures are invisible.
    %   Run with runtests('signalvis.test').

    properties
        DataRoot
        OutputDir
        Locations
        Pairs
        Frequencies
        Scan1
        Scan2
    end

    methods (TestClassSetup)
        function loadData(testCase)
            testCase.DataRoot = meritDataRoot();
            testCase.assertNotEmpty(testCase.DataRoot, 'Add the MERIT folder to the MATLAB path before running these tests.');
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            testCase.OutputDir = folder.Folder;
            testCase.Locations = dlmread(fullfile(testCase.DataRoot, 'antenna_locations.csv'));
            testCase.Pairs = dlmread(fullfile(testCase.DataRoot, 'channel_names.csv'));
            testCase.Frequencies = dlmread(fullfile(testCase.DataRoot, 'frequencies.csv'));
            testCase.Scan1 = dlmread(fullfile(testCase.DataRoot, 'B0_P3_p000.csv'));
            testCase.Scan2 = dlmread(fullfile(testCase.DataRoot, 'B0_P3_p036.csv'));
        end
    end

    methods (TestMethodSetup)
        function closeNewFigures(testCase)
            before = findall(0, 'Type', 'figure');
            testCase.addTeardown(@() delete(setdiff(findall(0, 'Type', 'figure'), before)));
        end
    end

    methods (Test)
        function complexQuantities(testCase)
            % Complex quantities.
            s = [1+2i, 3-4i; -2+1i, -1-3i; 2-2i, 1+1i];
            [~, v] = signalvis.signalViewer(s, [], [], 'Visible', 'off');
            state = v.GetSelection();
            testCase.verifyTrue(strcmp(state.Quantity, 'both'), 'Complex input shows magnitude and phase by default.');
            lines = v.GetDisplayedData();
            testCase.verifyTrue(numel(lines) == 4 && numel(plotted(v)) == 4);
            testCase.verifyTrue(numel(findobj(v.PlotPanel, 'Type', 'axes')) == 2);
            checkLine(lines, 'magnitude', 1, 1, abs(s(:,1)));
            checkLine(lines, 'phase', 1, 2, angle(s(:,2)));
            v.SetDisplay('Quantity', 'real'); checkLine(v.GetDisplayedData(), 'real', 1, 2, real(s(:,2)));
            v.SetDisplay('Quantity', 'imaginary'); checkLine(v.GetDisplayedData(), 'imaginary', 1, 1, imag(s(:,1)));
            testCase.verifyError(@() v.SetDisplay('Quantity', 'value'), 'signalvis:signalViewer:Quantity');
            [~, v] = signalvis.signalViewer(real(s), [], [], 'InputType', 'complex', 'Quantity', 'both', 'Visible', 'off');
            testCase.verifyTrue(numel(v.GetDisplayedData()) == 4, 'An explicitly complex real-valued spectrum has phase.');
            [~, v] = signalvis.signalViewer([1+1i; complex(Inf,1); 1-1i], [], [], 'Quantity', 'phase', 'Visible', 'off');
            y = v.GetDisplayedData(); y = y(1).Y;
            testCase.verifyTrue(~isfinite(y(2)) && isfinite(y(3)), 'Non-finite complex samples stay local gaps.');
        end

        function waveforms(testCase)
            % Real waveforms.
            w = [-2 1; 1 0; 3 -4];
            [~, v] = signalvis.signalViewer(w, [], [], 'Visible', 'off');
            lines = v.GetDisplayedData();
            testCase.verifyTrue(strcmp(selectionField(v, 'Quantity'), 'value'));
            checkLine(lines, 'value', 1, 1, w(:,1)); checkLine(lines, 'value', 1, 2, w(:,2));
            closeEnough(lines(1).X, [1;2;3]);
            v.SetDisplay('Quantity', 'magnitude'); checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [2;1;3]);
            testCase.verifyError(@() v.SetDisplay('Quantity', 'phase'), 'signalvis:signalViewer:Quantity');
            offered = get(v.QuantityPopup, 'String');
            testCase.verifyTrue(isequal(sort(offered(:))', sort({'Magnitude', 'Value'})), 'Only valid quantities are offered.');
        end

        function magnitudeInput(testCase)
            % Magnitude input and dB conversion.
            values = [-65 -30; -20 -5; -3 2];
            [~, v] = signalvis.signalViewer(values, [], [], 'InputType', 'magnitude', 'InputMagnitudeScale', 'dB', 'Visible', 'off');
            lines = v.GetDisplayedData();
            checkLine(lines, 'magnitude', 1, 1, values(:,1)); checkLine(lines, 'magnitude', 1, 2, values(:,2));
            testCase.verifyTrue(strcmp(lines(1).QuantityLabel, 'Magnitude (dB)'), 'dB input is displayed in dB by default.');
            v.SetDisplay('MagnitudeScale', 'linear');
            checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, 10.^(values(:,1)/20));
            [~, v] = signalvis.signalViewer([-40; 0; 20], [], [], 'InputType', 'magnitude', 'InputMagnitudeScale', 'dB', ...
                'MagnitudeScale', 'linear', 'Visible', 'off');
            checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [.01; 1; 10]);
            [~, v] = signalvis.signalViewer([0; .01; 1; NaN; Inf], [], [], 'InputType', 'magnitude', ...
                'MagnitudeScale', 'dB', 'Visible', 'off');
            checkLine(v.GetDisplayedData(), 'magnitude', 1, 1, [-Inf; -40; 0; NaN; Inf]);
            offered = get(v.QuantityPopup, 'String');
            testCase.verifyTrue(isequal(offered(:)', {'Magnitude'}), 'Magnitude input offers magnitude only.');
            testCase.verifyError(@() signalvis.signalViewer([1; -1], [], [], 'InputType', 'magnitude', 'Visible', 'off'), ...
                'signalvis:signalViewer:InputMagnitudeScale');
        end

        function phaseInput(testCase)
            % Phase input, units and unwrapping.
            p = [170; 190; NaN; 530; 550];
            [~, v] = signalvis.signalViewer(p, [], [], 'InputType', 'phase', 'InputPhaseUnits', 'degrees', 'Visible', 'off');
            checkLine(v.GetDisplayedData(), 'phase', 1, 1, p);
            v.SetDisplay('PhaseUnits', 'radians');
            checkLine(v.GetDisplayedData(), 'phase', 1, 1, p*pi/180);
            [~, v] = signalvis.signalViewer([170; -170; NaN; 170; -170], [], [], 'InputType', 'phase', ...
                'InputPhaseUnits', 'degrees', 'UnwrapPhase', true, 'Visible', 'off');
            checkLine(v.GetDisplayedData(), 'phase', 1, 1, [170; 190; NaN; 170; 190]);
            testCase.verifyError(@() v.SetDisplay('Quantity', 'magnitude'), 'signalvis:signalViewer:Quantity');
            s = exp(1i * (0:0.9:9)');
            [~, v] = signalvis.signalViewer(s, [], [], 'Quantity', 'phase', 'UnwrapPhase', true, 'Visible', 'off');
            checkLine(v.GetDisplayedData(), 'phase', 1, 1, unwrap(angle(s)));
        end

        function axisUnits(testCase)
            % Sample axis units.
            [~, v] = signalvis.signalViewer([1; 2; 3], [1e9 2e9 3e9], [], 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Visible', 'off');
            lines = v.GetDisplayedData(); closeEnough(lines(1).X, [1; 2; 3]);
            ax = findobj(v.PlotPanel, 'Type', 'axes');
            testCase.verifyTrue(strcmp(get(get(ax(1), 'XLabel'), 'String'), 'Frequency (GHz)'));
            [~, v] = signalvis.signalViewer([1; 2], [1; 2], [], 'AxisUnits', 'ns', 'DisplayAxisUnits', 's', 'Visible', 'off');
            lines = v.GetDisplayedData(); closeEnough(lines(1).X, [1e-9; 2e-9]);
            testCase.verifyError(@() signalvis.signalViewer([1; 2], [1; 2], [], 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'ns', 'Visible', 'off'), ...
                'signalvis:signalViewer:DisplayAxisUnits');
        end

        function txRxSelection(testCase)
            % Tx and Rx selection.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
            state = v.GetSelection();
            % Each ring lists pairs with the lower antenna as Tx: 10, 20 and 24 never transmit; 1, 11 and 21 never receive.
            testCase.verifyTrue(isequal(state.Channels, 1:96) && isequal(state.Tx, setdiff(1:24, [10 20 24])) && isequal(state.Rx, setdiff(1:24, [1 11 21])));
            v.SelectTx(5);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, find(pairs(:,1) == 5)'), 'Tx 5 with all Rx shows the channels transmitted by 5.');
            testCase.verifyTrue(all(strncmp(state.ChannelLabels, '5-', 2)));
            v.SelectTx(unique(pairs(:,1))); v.SelectRx(5);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, find(pairs(:,2) == 5)'), 'Strict matching: Rx 5 shows channels received by 5.');
            v.SelectTx([1 2]); v.SelectRx([3 4]);
            expected = find(ismember(pairs(:,1), [1 2]) & ismember(pairs(:,2), [3 4]))';
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, expected) && numel(expected) == 4);
            tablesAgree(v);
            lines = v.GetDisplayedData();
            testCase.verifyTrue(isequal(unique([lines.Channel]), expected));
            testCase.verifyTrue(numel(plotted(v)) == numel(lines));
            v.SelectRx([]);
            testCase.verifyTrue(isempty(selectionField(v, 'Channels')) && isempty(v.GetDisplayedData()));
            testCase.verifyError(@() v.SelectTx(10), 'signalvis:signalViewer:Tx');
            testCase.verifyError(@() v.SelectRx(11), 'signalvis:signalViewer:Rx');
        end

        function channelList(testCase)
            % Channel list and table callbacks.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
            allTx = unique(pairs(:,1))'; allRx = unique(pairs(:,2))';
            tablesAgree(v);
            % Channel ticks change only the channels; the Tx and Rx ticks stay as they are.
            v.SelectChannels([3 1 7]);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, [1 3 7]));
            testCase.verifyTrue(isequal(state.Tx, allTx) && isequal(state.Rx, allRx), 'Channel ticks leave the Tx and Rx ticks unchanged.');
            tablesAgree(v);
            editCell(v.ChannelTable, 3, 2, false);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, [1 7]), 'Unticking a channel hides only that channel.');
            testCase.verifyTrue(isequal(state.Tx, allTx) && isequal(state.Rx, allRx));
            tablesAgree(v);
            editCell(v.ChannelTable, 50, 2, true);
            testCase.verifyTrue(isequal(selectionField(v, 'Channels'), [1 7 50]));
            tablesAgree(v);
            data = get(v.ChannelTable, 'Data');
            testCase.verifyTrue(strcmp(data{1, 1}, '1-2') && data{1, 2} == true && data{2, 2} == false);
            % Tx and Rx ticks to channel ticks.
            v.SelectTx(allTx); v.SelectRx(allRx);
            editCell(v.TxTable, 1, 2, false);
            state = v.GetSelection();
            testCase.verifyTrue(~any(state.Tx == 1) && isequal(state.Channels, find(pairs(:,1) ~= 1)'), ...
                'A Tx table edit recomputes the channel ticks.');
            tablesAgree(v);
            v.SelectRx([]); editCell(v.RxTable, 1, 2, true);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Rx, 2) && isempty(state.Channels), 'Tx 1 is unticked, so Rx 2 alone matches nothing.');
            tablesAgree(v);
            v.SelectChannels([]);
            state = v.GetSelection();
            testCase.verifyTrue(isempty(state.Channels) && isequal(state.Rx, 2), 'Clearing the channels leaves the Tx and Rx ticks unchanged.');
            tablesAgree(v);
            v.SelectChannels(1:96);
            state = v.GetSelection();
            testCase.verifyTrue(numel(state.Channels) == 96 && isequal(state.Rx, 2));
            tablesAgree(v);
        end

        function referenceView(testCase)
            % Channel with its reference channels.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            n = artefact.antennaNeighbours(locations, pairs, 'nearest', 'K', 2);
            refs = artefact.referenceChannels(n, pairs);
            [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'References', refs, 'Visible', 'off');
            c = find(pairs(:,1) == 1 & pairs(:,2) == 3);
            v.ShowReference(c);
            state = v.GetSelection();
            testCase.verifyTrue(isequal(state.Channels, sort([c refs{c}])) && state.ReferenceFor == c, ...
                'The channel and its reference channels are shown.');
            testCase.verifyTrue(isequal(state.ChannelLabels, {'1-2', '1-3', '1-4'}), 'Receiver rule: channel 1-3 has the reference 1-2 and 1-4.');
            tablesAgree(v);
            lines = v.GetDisplayedData();
            testCase.verifyTrue(all([lines([lines.Channel] == c).Highlighted]) && ~any([lines([lines.Channel] ~= c).Highlighted]));
            drawn = plotted(v);
            widths = cell2mat(get(drawn, 'LineWidth'));
            drawnNames = get(drawn, 'DisplayName');
            testCase.verifyTrue(all(strcmp(drawnNames(widths > 1), '1-3')) && any(widths > 1), 'Only the chosen channel is drawn thick.');
            set(v.ReferencePopup, 'Value', 2);
            callback = get(v.ReferencePopup, 'Callback'); callback(v.ReferencePopup, []);
            testCase.verifyTrue(selectionField(v, 'ReferenceFor') == 1, 'The popup chooses the channel.');
            v.SelectTx(1);
            testCase.verifyTrue(selectionField(v, 'ReferenceFor') == 0, 'A Tx selection clears the chosen channel.');
            [~, editor] = artefact.neighbourhoodEditor(locations, pairs, 'Visible', 'off');
            [~, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'References', editor.GetResult(), 'Visible', 'off');
            v.ShowReference(c);
            testCase.verifyTrue(isequal(selectionField(v, 'Channels'), sort([c refs{c}])), 'The editor result is accepted.');
            testCase.verifyError(@() v.ShowReference(97), 'signalvis:signalViewer:Channel');
            [~, w] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
            testCase.verifyError(@() w.ShowReference(1), 'signalvis:signalViewer:References');
        end

        function datasets(testCase)
            % Several datasets.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            scan2 = testCase.Scan2;
            subtracted = scan1 - scan2;
            [~, v] = signalvis.signalViewer({scan1, scan2, subtracted}, frequencies, pairs, ...
                'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, 'InitialTx', 1, 'InitialRx', [2 3], ...
                'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Quantity', 'magnitude', 'Visible', 'off');
            lines = v.GetDisplayedData();
            testCase.verifyTrue(numel(lines) == 6);
            checkLine(lines, 'magnitude', 3, 10, abs(subtracted(:,10)));
            drawn = plotted(v);
            testCase.verifyTrue(numel(drawn) == 6);
            for k = 1:numel(drawn)
                name = get(drawn(k), 'DisplayName');
                match = drawn(strcmp(get(drawn, 'DisplayName'), strrep(name, '(Original)', '(Rotated)')));
                if ~isempty(strfind(name, '(Original)')) %#ok<STREMP>
                    testCase.verifyTrue(isequal(get(drawn(k), 'Color'), get(match, 'Color')), 'A channel keeps its colour in every dataset.');
                    testCase.verifyTrue(~strcmp(get(drawn(k), 'LineStyle'), get(match, 'LineStyle')), 'Datasets differ in line style.');
                end
            end
            v.SelectDatasets([2 3]);
            drawn = plotted(v);
            styles = get(drawn, 'LineStyle'); labels = get(drawn, 'DisplayName');
            testCase.verifyTrue(all(strcmp(styles(~cellfun(@isempty, strfind(labels, 'Subtracted'))), ':')), ...
                'A dataset keeps the line style given in the dataset table.');
            v.SelectDatasets([1 3]);
            lines = v.GetDisplayedData();
            testCase.verifyTrue(isequal(unique([lines.Dataset]), [1 3]));
            editCell(v.DatasetTable, 1, 3, false);
            testCase.verifyTrue(isequal(selectionField(v, 'Datasets'), 3));
            dB = 20 * log10(abs(scan1));
            [~, v] = signalvis.signalViewer({scan1, dB}, frequencies, pairs, 'InputType', {'complex', 'magnitude'}, ...
                'InputMagnitudeScale', {'linear', 'dB'}, 'InitialTx', 1, 'InitialRx', 2, 'Visible', 'off');
            lines = v.GetDisplayedData();
            testCase.verifyTrue(sum(strcmp({lines.Quantity}, 'magnitude')) == 2 && sum(strcmp({lines.Quantity}, 'phase')) == 1, ...
                'The magnitude-only dataset contributes to the magnitude axis only.');
            v.SetDisplay('MagnitudeScale', 'db');
            lines = v.GetDisplayedData();
            magnitudes = lines(strcmp({lines.Quantity}, 'magnitude'));
            closeEnough(magnitudes(1).Y, magnitudes(2).Y);
            v.SetDisplay('Quantity', 'phase');
            testCase.verifyTrue(~isempty(strfind(get(v.Status, 'String'), 'Dataset 2'))); %#ok<STREMP>
        end

        function paging(testCase)
            % Individual layout and paging.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            scan2 = testCase.Scan2;
            [fig, v] = signalvis.signalViewer({scan1, scan2}, frequencies, pairs, 'Layout', 'individual', ...
                'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Visible', 'off');
            state = v.GetSelection();
            testCase.verifyTrue(state.Pages == 16 && state.Page == 1);
            lines = v.GetDisplayedData();
            testCase.verifyTrue(isequal(unique([lines.Channel]), 1:6) && numel(lines) == 6 * 2 * 2);
            testCase.verifyTrue(numel(findobj(v.PlotPanel, 'Type', 'axes')) == 12);
            next = findobj(fig, 'Style', 'pushbutton', 'String', 'Next');
            callback = get(next, 'Callback'); callback(next, []);
            lines = v.GetDisplayedData();
            testCase.verifyTrue(selectionField(v, 'Page') == 2 && isequal(unique([lines.Channel]), 7:12));
            v.SetDisplay('Page', 16);
            testCase.verifyTrue(isequal(unique(displayedField(v, 'Channel')), 91:96));
            v.SelectTx(1);
            state = v.GetSelection();
            testCase.verifyTrue(state.Page == 1 && state.Pages == 2, 'The page is limited to the new selection.');
            testCase.verifyError(@() v.SetDisplay('Page', 3), 'signalvis:signalViewer:Page');
            v.SetDisplay('Layout', 'overlay');
            testCase.verifyTrue(strcmp(get(next, 'Visible'), 'off'));
            % Column widths follow the table width (the resize handler is called
            % directly because invisible figures receive no resize events).
            for size = [1257 660; 2355 1238]'
                set(fig, 'Units', 'pixels', 'Position', [1 1 size']);
                resize = get(fig, 'SizeChangedFcn'); resize(fig, []);
                width = getpixelposition(v.ChannelTable);
                columns = cell2mat(get(v.ChannelTable, 'ColumnWidth'));
                testCase.verifyTrue(sum(columns) <= width(3) && sum(columns) >= width(3) - 30, ...
                    'Channel columns fill the table without exceeding it.');
            end
        end

        function invalidInputs(testCase)
            % Invalid inputs precede graphics.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            scan2 = testCase.Scan2;
            before = findall(0, 'Type', 'figure');
            testCase.verifyError(@() signalvis.signalViewer({scan1, scan1(1:10,:)}, [], pairs, 'Visible', 'off'), 'signalvis:signalViewer:Signals');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies(1:5), pairs, 'Visible', 'off'), 'signalvis:signalViewer:SampleAxis');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs(1:5,:), 'Visible', 'off'), 'signalvis:signalViewer:ChannelPairs');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'InputType', 'waveform', 'Visible', 'off'), 'signalvis:signalViewer:InputType');
            testCase.verifyError(@() signalvis.signalViewer({scan1, scan2}, frequencies, pairs, 'InputType', {'complex'}, 'Visible', 'off'), 'signalvis:signalViewer:InputType');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'Quantity', 'value', 'Visible', 'off'), 'signalvis:signalViewer:Quantity');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'InitialTx', 24, 'Visible', 'off'), 'signalvis:signalViewer:InitialTx');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'References', {1}, 'Visible', 'off'), 'signalvis:signalViewer:References');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'References', repmat({200}, 96, 1), 'Visible', 'off'), 'signalvis:signalViewer:References');
            testCase.verifyError(@() signalvis.signalViewer(scan1, frequencies, pairs, 'DatasetNames', {'a', 'b'}, 'Visible', 'off'), 'signalvis:signalViewer:DatasetNames');
            testCase.verifyTrue(isequal(findall(0, 'Type', 'figure'), before), 'No figure is created for invalid inputs.');
        end

        function figuresAndClosing(testCase)
            % Unrelated figures and closing.
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            other = figure('Visible', 'off'); plot(1:3);
            [fig, v] = signalvis.signalViewer(scan1, frequencies, pairs, 'Visible', 'off');
            v.SelectTx(2);
            testCase.verifyTrue(isgraphics(other) && numel(get(get(other, 'CurrentAxes'), 'Children')) == 1);
            delete(fig);
            v.SelectTx(3);
            testCase.verifyTrue(isequal(selectionField(v, 'Tx'), 3), 'Selections still work after the figure is closed.');
            testCase.verifyTrue(~isempty(v.GetDisplayedData()));
            delete(other);
        end

        function meritPreviews(testCase)
            % MERIT data and previews.
            locations = testCase.Locations;
            pairs = testCase.Pairs;
            frequencies = testCase.Frequencies;
            scan1 = testCase.Scan1;
            scan2 = testCase.Scan2;
            outputDir = testCase.OutputDir;
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
    end
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
