%VIEWMERITSIGNALS Compare MERIT example scans interactively by Tx and Rx antenna.
% MERIT's example data are in the data folder beside its +merit package.
delayFile=which('merit.process.delay');
if isempty(delayFile)
    error('Add the MERIT folder to the MATLAB path before running this example.');
end
dataRoot=fullfile(fileparts(fileparts(fileparts(delayFile))),'data');
frequencies=dlmread(fullfile(dataRoot,'frequencies.csv'));
antenna_locations=dlmread(fullfile(dataRoot,'antenna_locations.csv'));
channel_names=dlmread(fullfile(dataRoot,'channel_names.csv'));
scan1=dlmread(fullfile(dataRoot,'B0_P3_p000.csv'));
scan2=dlmread(fullfile(dataRoot,'B0_P3_p036.csv'));

% Three datasets with the same 96 channels: original, rotated and
% rotation-subtracted scans. Each channel's reference channels (from the
% default neighbourhoods, receiver rule) can be shown with it.
neighbours=artefact.antennaNeighbours(antenna_locations,channel_names);
references=artefact.referenceChannels(neighbours,channel_names);
[fig,viewer]=signalvis.signalViewer({scan1,scan2,scan1-scan2},frequencies,channel_names, ...
    'DatasetNames',{'Original','Rotated','Subtracted'},'References',references, ...
    'AxisUnits','Hz','DisplayAxisUnits','GHz','InitialTx',1,'InitialRx',[2 3]);

% Tick Tx and Rx antennas, groups, channels or datasets in the figure, or
% use the viewer functions, for example:
%   viewer.SelectTx(5); viewer.SelectRx(6:10);
%   viewer.ShowReference(10);   % channel 1-3 with its reference channels
%   viewer.SetDisplay('Quantity','magnitude','MagnitudeScale','db','Layout','individual');
%   selection=viewer.GetSelection();
selection=viewer.GetSelection();
fprintf('Showing channels %s for %d datasets.\n',strjoin(selection.ChannelLabels,', '),numel(selection.Datasets));

% MERIT's getting-started variables are already converted: magnitudes in
% dB and unwrapped phase in radians. Declare their types so that they are
% displayed as supplied and not converted again.
magnitudeDb=20*log10(abs(scan1));
phaseUnwrapped=unwrap(angle(scan1));
signalvis.signalViewer({magnitudeDb,phaseUnwrapped},frequencies,channel_names, ...
    'InputType',{'magnitude','phase'},'InputMagnitudeScale',{'dB','linear'}, ...
    'DatasetNames',{'Magnitude (dB)','Unwrapped phase'},'Quantity','both', ...
    'AxisUnits','Hz','DisplayAxisUnits','GHz','InitialTx',1,'InitialRx',2);
