% SIGNALVIS Display and comparison of MERIT channel signals.
% Part of MERIT-Extensions.
%
% Interactive tools
%   signalViewer       - Choose interactively which channel signals to display and compare.
%   inspectPointDelays - Compare original signals with the signals delayed for one imaging point.
%
% Signals are samples-by-channels arrays, as in MERIT; channel_names gives
% the transmitting and receiving antenna of each column. inspectPointDelays
% requires MERIT on the path; signalViewer uses base MATLAB only.
%
% Tests: runtests('signalvis.test'), matlab.unittest test classes in +signalvis/+test.
%
% Documentation: doc/README.md in the MERIT-Extensions folder.
%
% See also artefact
