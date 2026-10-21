%INSPECTSYNTHETICTIME Deterministic time-domain point-delay inspector example.
% Add the MERIT-EXT folder and the MERIT folder to the MATLAB path.
dt=1e-9;
sampleAxis=(0:127)';
t=sampleAxis*dt;
signals=[sin(2*pi*35e6*t),cos(2*pi*22e6*t)];
points=[0 0 0; 1 0 0; 0 1 0; 1 1 0];
% Each column is a point, each row a channel. Positive and negative delays
% retain MERIT's focus convention; time-domain shifts are rounded to samples.
delaysSamples=[0 2 -1 3; 1 -2 0 2];
image=[1;2;3;4];
axes_={0:1,0:1,0};

[figBefore,before]=signalvis.inspectPointDelays(signals,sampleAxis,points,delaysSamples, ...
    'Domain','time','AxisUnits','samples','SampleInterval',dt, ...
    'DelayUnits','samples','Axes',axes_,'Image',image,'SliceZ',0, ...
    'ChannelLabels',[1 1;1 2],'Layout','individual','ChannelsPerPage',1, ...
    'Visible','on');
selection=before.GetSelection();
fprintf('Selected point %d, delays (ns): %g %g\n',selection.PointIndex,selection.DelaysSeconds*1e9);
before.SelectPoint(3);
before.SelectSlice(0);

% Optional window example. The output has fewer samples, so WindowAxis is
% supplied in the same sample-coordinate units as sampleAxis.
windowAxis=(8:119)';
window=@(x)x(9:120,:);
[figWindowed,windowed]=signalvis.inspectPointDelays(signals,sampleAxis,points,delaysSamples, ...
    'Domain','time','AxisUnits','samples','SampleInterval',dt, ...
    'DelayUnits','samples','Window',window,'WindowAxis',windowAxis, ...
    'Axes',axes_,'Visible','on');
windowSelection=windowed.GetSelection();
disp(windowSelection.ComparedAxis(1:3));
