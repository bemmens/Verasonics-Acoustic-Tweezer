%load PogoPinTest.mat

nrepeats = 3;
Data = zeros(nrepeats,8);
for i = 1:nrepeats
    class(i)
    ProbeZdata = ProbeImpedanceCheck(1);
    data = ProbeZdata.MeasZperCh([1,2,3,4,6,7,8,9]);
    plot(ProbeZdata.MeasZperCh([1,2,3,4,6,7,8,9]));
    Data(i,:) = data
end
xlabel('Channel')
ylabel('Impedance Magnitude (Ohms)')