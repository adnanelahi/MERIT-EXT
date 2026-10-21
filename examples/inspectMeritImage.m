%INSPECTMERITIMAGE Inspect MERIT channels before and after beamforming.
% Add MERIT-EXT and MERIT to the MATLAB path, then run this file.
% MERIT's example data are in the data folder beside its +merit package.
delayFile=which('merit.process.delay');
if isempty(delayFile)
    error('Add the MERIT folder to the MATLAB path before running this example.');
end
dataRoot=fullfile(fileparts(fileparts(fileparts(delayFile))),'data');
frequencies=dlmread(fullfile(dataRoot,'frequencies.csv'));
antennaLocations=dlmread(fullfile(dataRoot,'antenna_locations.csv'));
channelNames=dlmread(fullfile(dataRoot,'channel_names.csv'));
scan1=dlmread(fullfile(dataRoot,'B0_P3_p000.csv'));
scan2=dlmread(fullfile(dataRoot,'B0_P3_p036.csv'));

% Keep the first eight channel pairs to make the interactive comparison
% manageable. These are the same rotation-subtracted frequency signals that
% will be passed to the beamformer below.
channels=1:min(8,size(scan1,2));
signals=scan1(:,channels)-scan2(:,channels);
channelPairs=channelNames(channels,:);
[points,axes_]=merit.domain.hemisphere('radius',7e-2,'resolution',2.5e-3);
delayFunction=merit.beamform.get_delays(channelPairs,antennaLocations, ...
    'relative_permittivity',8);

[figBefore,before]=signalvis.inspectPointDelays(signals,frequencies,points,delayFunction, ...
    'AxisUnits','Hz','DisplayAxisUnits','MHz','CoordinateUnits','m','DisplayCoordinateUnits','mm', ...
    'Axes',axes_,'SliceZ',35e-3,'ChannelLabels',channelPairs, ...
    'Layout','overlay','Visible','on');
selection=before.GetSelection();
fprintf('Before reconstruction: point %d at [%.4g %.4g %.4g] m\n', ...
    selection.PointIndex,selection.PointMetres);
% Click a point in the map or use the returned programmatic controls:
% before.SelectPoint(1234); before.SelectSlice(35e-3); before.GetSelection()

% The image is MERIT's point-first beamformer output, not a raster slice.
image=merit.beamform(signals,frequencies,points,delayFunction,merit.beamformers.DAS);
[figAfter,after]=signalvis.inspectPointDelays(signals,frequencies,points,delayFunction, ...
    'AxisUnits','Hz','DisplayAxisUnits','MHz','CoordinateUnits','m','DisplayCoordinateUnits','mm', ...
    'Axes',axes_,'SliceZ',35e-3,'Image',image,'ImageComponent','auto', ...
    'ChannelLabels',channelPairs,'Layout','overlay','Visible','on');
reconstructedSelection=after.GetSelection();
disp(reconstructedSelection.ImageValue);
