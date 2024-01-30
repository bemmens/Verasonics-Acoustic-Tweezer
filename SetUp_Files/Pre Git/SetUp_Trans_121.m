
Trans.name = 'Immasonic_3MHz_121_2D'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.Bandwidth = [2,4]; 
Trans.frequency = 3.2;

el_Stats = load("C:\Users\gv19838\OneDrive - University of Bristol\PhD\Verasonics\File_Share\Bristol arrays\Imasonic 2D matrix 121els 3.00MHz 1.00mm pitch.mat");
ElPos = zeros(121,5);
ElPos(:,1) = el_Stats.array.el_xc;
ElPos(:,2) = el_Stats.array.el_yc;

mmToNW = 1e-3*Trans.frequency*1e6/Resouce.Parameters.speedOfSound;

Trans.type = 2;
Trans.numelements = 121;
Trans.ElementPos = ElPos*1e3; 
Trans.elementWidth = 0.8;

Theta = (-pi/2:pi/100:pi/2);
X = Trans.elementWidth*pi*sin(Theta); % Default see Manual

Trans.ElementSens = abs(cos(Theta).*(sin(X)./X));
Trans.maxHighVoltage = 100/2;  % maxVpp/2
Trans.impedance = 6.6-137.1i;
Trans.ConnectES = 1:121 ;
Trans.connType = -1; % automatically detect UTA Module type
Trans.spacingMm = 1; % centre to centre (ctc)
Trans.spacing = Trans.spacingMm*mmToNW;

save("Barney/data_files/Trans_121")