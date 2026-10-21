%MERITNEIGHBOURHOODS Antenna neighbourhoods and reference channels for the MERIT example data.
% MERIT's example data are in the data folder beside its +merit package.
delayFile=which('merit.process.delay');
if isempty(delayFile)
    error('Add the MERIT folder to the MATLAB path before running this example.');
end
dataRoot=fullfile(fileparts(fileparts(fileparts(delayFile))),'data');
antenna_locations=dlmread(fullfile(dataRoot,'antenna_locations.csv'));
channel_names=dlmread(fullfile(dataRoot,'channel_names.csv'));
scan1=dlmread(fullfile(dataRoot,'B0_P3_p000.csv'));
frequencies=dlmread(fullfile(dataRoot,'frequencies.csv'));

% Each antenna's neighbourhood: its two nearest antennas among those with a
% measured channel to it (on this array, the adjacent antennas in its ring).
neighbours=artefact.antennaNeighbours(antenna_locations,channel_names,'nearest','K',2);
% Reference channels by the receiver rule: for channel i-j, the channels
% from i to the neighbours of j; the channel itself is left out.
references=artefact.referenceChannels(neighbours,channel_names);
c=find(channel_names(:,1)==1&channel_names(:,2)==3);
fprintf('Channel 1-3: reference channels %s\n',mat2str(channel_names(references{c},:)));

% Interactive: choose an antenna to see its neighbours, switch on Edit
% neighbours to change them, and choose a channel to see its reference.
[fig,editor]=artefact.neighbourhoodEditor(antenna_locations,channel_names,'DisplayCoordinateUnits','mm');

% After editing: result=editor.GetResult(); result.References{c} lists the
% reference channels of channel c. Show a channel with its reference
% channels in the signal viewer:
[viewFig,viewer]=signalvis.signalViewer(scan1,frequencies,channel_names,'References',editor.GetResult(), ...
    'AxisUnits','Hz','DisplayAxisUnits','GHz');
viewer.ShowReference(c);
