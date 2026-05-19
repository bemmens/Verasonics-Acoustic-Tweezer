t = (1:scpSettings.RecordLength)*1e6/scpSettings.SampleFrequency; % us

twenties = linspace(0,5*20,6);

figure(1)
imagesc(saveData)
colormap("gray")
xlabel('Channel');
ylabel('Time [samples]');

figure(2)
subplot(4,1,1)
p1 = plot(t,saveData(:,2));
xline(twenties)
xlabel('Time [us]');
ylabel('Voltage [V]');
legend(p1,['Channel 1'])
% ylim([-0.08,0.08])
xlim([0,20])

subplot(4,1,2)
p2 = plot(t,saveData(:,29));
xline(twenties)
xlabel('Time [us]');
ylabel('Voltage [V]');
legend(p2,['Channel 28'])
% ylim([-0.08,0.08])
xlim([0,20])

subplot(4,1,3)
p2 = plot(t,saveData(:,60));
xline(twenties)
xlabel('Time [us]');
ylabel('Voltage [V]');
legend(p2,['Channel 59'])
% ylim([-0.08,0.08])
xlim([0,20])

subplot(4,1,4)
p3 = plot(t,saveData(:,115));
xline(twenties)
xlabel('Time [us]');
ylabel('Voltage [V]');
legend(p3,['Channel 115'])
% ylim([-0.08,0.08])
xlim([0,20])
