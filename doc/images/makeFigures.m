function makeFigures()
%MAKEFIGURES Create the figures and window images of the documentation.
%   Run with MERIT and MERIT-Extensions on the path. The images are written
%   to the folder of this script and overwrite the existing ones.

outputDir = fileparts(mfilename('fullpath'));
dataRoot = fullfile(fileparts(fileparts(fileparts(which('merit.process.delay')))), 'data');
locations = dlmread(fullfile(dataRoot, 'antenna_locations.csv'));
pairs = dlmread(fullfile(dataRoot, 'channel_names.csv'));
frequencies = dlmread(fullfile(dataRoot, 'frequencies.csv'));
scan1 = dlmread(fullfile(dataRoot, 'B0_P3_p000.csv'));
scan2 = dlmread(fullfile(dataRoot, 'B0_P3_p036.csv'));

neighbourhoodFigure(locations, pairs, fullfile(outputDir, 'neighbourhoods.png'));
methodFigure(locations, pairs, fullfile(outputDir, 'distance-and-nearest.png'));
referenceFigure(locations, pairs, fullfile(outputDir, 'reference-channels.png'));
editorImage(locations, pairs, fullfile(outputDir, 'neighbourhood-editor.png'));
viewerImage(locations, pairs, frequencies, scan1, scan2, fullfile(outputDir, 'signal-viewer.png'));
inspectorImage(locations, pairs, frequencies, scan1, scan2, fullfile(outputDir, 'point-inspector.png'));
end

% ---- Explanatory figures ----

function neighbourhoodFigure(locations, pairs, file)
neighbours = artefact.antennaNeighbours(locations, pairs);
limit = artefact.internal.defaultDistance(locations, artefact.internal.candidateNeighbours(pairs, size(locations, 1), true));
fig = newFigure([1000 450]);
ax = subplot(1, 2, 1, 'Parent', fig);
P = locations * 1000;
drawRings(ax, P, 'side');
title(ax, 'Side view: three rings');
ax = subplot(1, 2, 2, 'Parent', fig);
drawRings(ax, P, 'top', 1:10);
a = 3;
circle(ax, P(a, 1:2), limit * 1000);
highlight(ax, P, a, neighbours{a});
title(ax, {sprintf('Top view of ring 1: neighbours of antenna %d', a), ...
    sprintf('dotted circle: default distance, %.1f mm', limit * 1000)});
saveFigure(fig, file);
end

function methodFigure(locations, pairs, file)
P = locations * 1000;
rings = {1:10, 11:20, 21:24};
chosen = [3 13 22];
fig = newFigure([1000 680]);
settings = {{'distance', 'Distance', 0.05}, {'nearest', 'K', 2}};
names = {'within 50 mm', 'two nearest'};
for k = 1:2
    neighbours = artefact.antennaNeighbours(locations, pairs, settings{k}{:});
    for r = 1:3
        ax = subplot(2, 3, (k - 1) * 3 + r, 'Parent', fig);
        a = chosen(r);
        drawRings(ax, P, 'top', rings{r});
        if k == 1, circle(ax, P(a, 1:2), 50); end
        highlight(ax, P, a, neighbours{a});
        title(ax, sprintf('Ring %d, %s: %d neighbours', r, names{k}, numel(neighbours{a})));
    end
end
saveFigure(fig, file);
end

function referenceFigure(locations, pairs, file)
P = locations * 1000;
neighbours = artefact.antennaNeighbours(locations, pairs);
c = find(pairs(:, 1) == 1 & pairs(:, 2) == 3);
rules = {'receiver', 'transmitter'};
titles = {'Receiver rule: 1-m for m next to 3', 'Transmitter rule: 1-m for m next to 1'};
fig = newFigure([1000 450]);
for k = 1:2
    references = artefact.referenceChannels(neighbours, pairs, 'Rule', rules{k});
    ax = subplot(1, 2, k, 'Parent', fig);
    drawRings(ax, P, 'top', 1:10);
    for r = references{c}(:).'
        drawChannel(ax, P, pairs(r, :), [.93 .6 .1], 2);
    end
    drawChannel(ax, P, pairs(c, :), [.85 0 0], 3);
    labels = arrayfun(@(r) sprintf('%d-%d', pairs(r, :)), references{c}, 'UniformOutput', false);
    title(ax, {titles{k}, ['channel 1-3 (red), references ' strjoin(labels, ', ') ' (orange)']});
end
saveFigure(fig, file);
end

% ---- Window images ----

function editorImage(locations, pairs, file)
points = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
[fig, editor] = artefact.neighbourhoodEditor(locations, pairs, 'DisplayCoordinateUnits', 'mm', 'ImagingDomain', points, 'Visible', 'off');
setWindowSize(fig);
editor.ChooseAntenna(3);
editor.ChooseChannel(find(pairs(:, 1) == 1 & pairs(:, 2) == 3));
callouts(fig, {[.045 .88], [.2185 .935], [.58 .935], [.58 .655], [.58 .4], [.58 .03], [.04 .083]});
saveFigure(fig, file);
end

function viewerImage(locations, pairs, frequencies, scan1, scan2, file)
neighbours = artefact.antennaNeighbours(locations, pairs);
references = artefact.referenceChannels(neighbours, pairs);
[fig, viewer] = signalvis.signalViewer({scan1, scan2, scan1 - scan2}, frequencies, pairs, ...
    'DatasetNames', {'Original', 'Rotated', 'Subtracted'}, 'References', references, ...
    'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', 'Visible', 'off');
setWindowSize(fig);
viewer.ShowReference(find(pairs(:, 1) == 1 & pairs(:, 2) == 3));
viewer.SelectDatasets([1 3]);
viewer.SetDisplay('Quantity', 'magnitude', 'MagnitudeScale', 'db');
callouts(fig, {[.08 .953], [.19 .953], [.155 .472], [.06 .212], [.222 .925], [.25 .86], [.222 .02], [.935 .953]});
saveFigure(fig, file);
end

function inspectorImage(locations, pairs, frequencies, scan1, scan2, file)
channels = 1:8;
signals = scan1(:, channels) - scan2(:, channels);
channelPairs = pairs(channels, :);
[points, axes_] = merit.domain.hemisphere('radius', 7e-2, 'resolution', 2.5e-3);
delays = merit.beamform.get_delays(channelPairs, locations, 'relative_permittivity', 8);
image = abs(merit.beamform(signals, frequencies, points, delays, merit.beamformers.DAS));
[fig, inspector] = signalvis.inspectPointDelays(signals, frequencies, points, delays, ...
    'Image', image, 'Axes', axes_, 'SliceZ', 35e-3, 'AxisUnits', 'Hz', 'DisplayAxisUnits', 'GHz', ...
    'DisplayCoordinateUnits', 'mm', 'ChannelLabels', channelPairs, 'Visible', 'off');
setWindowSize(fig);
onPlane = find(abs(points(:, 3) - 35e-3) < 1e-6);
[~, k] = max(image(onPlane));
inspector.SelectPoint(onPlane(k));
callouts(fig, {[.025 .93], [.018 .137], [.33 .93], [.67 .93], [.018 .075]});
saveFigure(fig, file);
end

% ---- Helpers ----

function fig = newFigure(sizePixels)
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [50 50 sizePixels]);
end

function setWindowSize(fig)
set(fig, 'Units', 'pixels', 'Position', [20 20 1600 900]);
drawnow;
end

function saveFigure(fig, file)
set(fig, 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
print(fig, file, '-dpng', '-r0');
close(fig);
end

function drawRings(ax, P, view, subset)
if nargin < 4, subset = 1:size(P, 1); end
hold(ax, 'on'); axis(ax, 'equal'); box(ax, 'on');
switch view
    case 'top'
        scatter(ax, P(subset, 1), P(subset, 2), 70, [.75 .75 .75], 'filled', 'MarkerEdgeColor', 'k');
        for a = subset
            text(ax, P(a, 1) * 1.13, P(a, 2) * 1.13, sprintf('%d', a), 'HorizontalAlignment', 'center', 'FontSize', 8);
        end
        xlabel(ax, 'x (mm)'); ylabel(ax, 'y (mm)');
        lim = 1.3 * max(abs(reshape(P(subset, 1:2), [], 1)));
        set(ax, 'XLim', [-lim lim], 'YLim', [-lim lim]);
    case 'side'
        scatter(ax, P(subset, 1), P(subset, 3), 70, [.75 .75 .75], 'filled', 'MarkerEdgeColor', 'k');
        set(ax, 'YDir', 'reverse');
        xlabel(ax, 'x (mm)'); ylabel(ax, 'z (mm), increasing downwards');
        rings = {1:10, 11:20, 21:24};
        names = {'ring 1, antennas 1-10', 'ring 2, antennas 11-20', 'ring 3, antennas 21-24'};
        for r = 1:3
            text(ax, max(P(rings{r}, 1)) + 8, mean(P(rings{r}, 3)), names{r}, 'FontSize', 8);
        end
        set(ax, 'XLim', [-85 150], 'YLim', [0 70]);
end
end

function highlight(ax, P, a, neighbours)
for n = neighbours
    plot(ax, P([a n], 1), P([a n], 2), '-', 'Color', [0 .45 .74], 'LineWidth', 2);
end
scatter(ax, P(neighbours, 1), P(neighbours, 2), 70, [0 .45 .74], 'filled', 'MarkerEdgeColor', 'k');
scatter(ax, P(a, 1), P(a, 2), 90, [.85 0 0], 'filled', 'MarkerEdgeColor', 'k');
end

function circle(ax, centre, radius)
t = linspace(0, 2 * pi, 200);
plot(ax, centre(1) + radius * cos(t), centre(2) + radius * sin(t), ':', 'Color', [.4 .4 .4]);
end

function drawChannel(ax, P, pair, colour, width)
plot(ax, P(pair, 1), P(pair, 2), '-', 'Color', colour, 'LineWidth', width);
scatter(ax, P(pair(1), 1), P(pair(1), 2), 90, colour, 'filled', 'MarkerEdgeColor', 'k');
end

function callouts(fig, positions)
% Numbered markers at normalised figure positions (lower-left corner of each marker).
for k = 1:numel(positions)
    uicontrol(fig, 'Style', 'text', 'String', sprintf('%d', k), 'Units', 'normalized', ...
        'Position', [positions{k} .016 .028], 'BackgroundColor', [1 .84 0], ...
        'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'center');
end
drawnow;
end
