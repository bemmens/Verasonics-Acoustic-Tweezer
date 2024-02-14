clear all

Trans.name = 'Imasonic_5MHz_1D'; 
Trans.units = 'mm';
Trans.id = -1;
Trans.frequency = 5;
Trans.Bandwidth = [0.6*5,1.6*5];
Trans.type = 0;
Trans.numelements = 64;

%% ----------- Generate Element Coordinates -------------

c_water = 1481;
lambda_mm = c_water*1e3/(Trans.frequency*1e6);

Trans.spacingMm = 0.63; %mm
interElementSpacing = 0.1; %mm
Trans.elementWidth = Trans.spacingMm - interElementSpacing; % mm

Trans.ElementPos = zeros(Trans.numelements,5);
Trans.ElementPos(:,1) = (0:(Trans.numelements-1))*Trans.spacingMm;
Trans.ElementPos = Trans.ElementPos - mean(Trans.ElementPos);
scatter(Trans.ElementPos(:,1),Trans.ElementPos(:,2),10,1:64)
pbaspect([1 1 1])

% Default (not correct)
Trans.ElementSens = BeamPattern(Trans.elementWidth*1e-3,lambda_mm*1e-3);

%% Voltage Parameters

Trans.maxHighVoltage = 96;  % maxVpp/2

% ------------- Impedence Measurement -----------------------
Trans.impedance = 19.75 - 30.53i;

Trans.ConnectES = 1:Trans.numelements;
Trans.connType = -1; % automatically detect UTA Module type

% Save all the structures to a .mat file.
savedir = 'C:\Users\verasonics\Documents\Vantage-4.8.4-2305101400\Verasonics-Tatsuki\';
save(strcat(savedir,'Trans_5MHz_4514')); 