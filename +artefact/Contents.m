% ARTEFACT Early-time artefact removal for MERIT measurements.
% Part of MERIT-Extensions.
%
% Antenna neighbourhoods and reference channels
%   antennaNeighbours   - Neighbourhood of each antenna from the antenna positions.
%   referenceChannels   - Reference channels of each channel from the neighbourhoods.
%   neighbourhoodEditor - Show and edit neighbourhoods and reference channels.
%
% Artefact removal
%   subtractAverage     - Subtract the average of each channel's reference channels.
%
% Average subtraction removes the early-time artefact by subtracting
% from each channel the average of its reference channels.
% These functions use base MATLAB only.
%
% Documentation: doc/README.md in the MERIT-Extensions folder.
%
% See also signalvis
