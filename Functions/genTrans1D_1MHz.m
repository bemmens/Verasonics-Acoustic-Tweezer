clear all

Trans.name = 'Imasonic_1MHz_1D'; 
Trans.units = 'mm';
Trans.id = -1;
Trans.frequency = 1;
Trans.Bandwidth = [0.5*Trans.frequency,1.5*Trans.frequency];
Trans.type = 0;
Trans.numelements = 64;

%% ----------- Generate Element Coordinates -------------
Trans.spacingMm = 1.5; %mm
interElementSpacing = 0.3; %mm
Trans.elementWidth = Trans.spacingMm - interElementSpacing; % mm

Trans.ElementPos = zeros(Trans.numelements,5);
Trans.ElementPos(:,1) = (0:(Trans.numelements-1))*Trans.spacingMm;
Trans.ElementPos = Trans.ElementPos - mean(Trans.ElementPos);
scatter(Trans.ElementPos(:,1),Trans.ElementPos(:,2),10,1:64)
pbaspect([1 1 1])

c_water = 1481;
c_aliminium = 6320; % m/s
lambda_mm = c_water*1e3/(Trans.frequency*1e6);

% Default (not correct)
Trans.ElementSens = BeamPattern(Trans.elementWidth*1e-3,lambda_mm*1e-3);

%% Voltage Parameters

Trans.maxHighVoltage = 96;  % maxVpp/2

% ------------- Impedence Measurement -----------------------
Trans.impedance = 23 - 266i;

Trans.ConnectES = 1:Trans.numelements;
Trans.connType = -1; % automatically detect UTA Module type

% Save all the structures to a .mat file.
savedir = 'C:\Users\verasonics\Documents\Vantage-4.8.4-2305101400\Verasonics-Tatsuki\';
save(strcat(savedir,'Trans_1MHz_64_Linear')); 