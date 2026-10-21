%VIEWSYNTHETICSIGNALS View real time-domain waveforms by Tx and Rx without MERIT.
% Four antennas, all six pairs, Gaussian-modulated pulses whose delay grows
% with the antenna separation.
t=(0:0.02:6)'*1e-9;                       % time axis in seconds
pairs=[1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
separation=[1 2 1 1 2 1];                 % in units of the antenna spacing
signals=zeros(numel(t),size(pairs,1));
for c=1:size(pairs,1)
    delay=1e-9+0.8e-9*separation(c);
    signals(:,c)=exp(-((t-delay)/0.25e-9).^2).*cos(2*pi*4e9*(t-delay))/separation(c);
end
noisy=signals+0.02*sin(2*pi*1.3e9*t+(1:6));

% Real input is displayed as a waveform; Magnitude shows its absolute value.
[fig,viewer]=signalvis.signalViewer({signals,noisy},t,pairs, ...
    'DatasetNames',{'Clean','With interference'},'AxisUnits','s','DisplayAxisUnits','ns');
viewer.SelectTx(1);                       % channels 1-2, 1-3 and 1-4
