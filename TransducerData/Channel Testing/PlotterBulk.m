t = (1:scpSettings.RecordLength)*1e6/scpSettings.SampleFrequency; % us


figure(1)
imagesc(saveData)
colormap("gray")
xlabel('Channel');
ylabel('Time [samples]');

figure(2)
plot(t,saveData)
xlabel('Time [us]');
ylabel('Voltage [V]');
