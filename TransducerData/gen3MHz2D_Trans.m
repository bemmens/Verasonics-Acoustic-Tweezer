clear all
%%
Trans.name = '3MHz2D'; 
Trans.id = -1;
Trans.connType = 12;
Trans.units = 'mm';
Trans.frequency = 3;

Trans.type = 2;
elPerRow = 11;
Trans.numelements = elPerRow^2;

%% Generate Element Positions
% Places all elements on a grid with 0,0 at the centre of the array.
pitch = 1;
Trans.spacingMm = pitch;
wavelength =1481/(Trans.frequency*1e6); % in m
Trans.spacing = wavelength/(pitch*1e-3);
xs = (-(elPerRow-1)/2:(elPerRow-1)/2)*pitch;
ys = reshape(repmat(-xs, elPerRow, 1), 1, []);

Trans.ElementPos = zeros(Trans.numelements,5); %[nx5 double] -> [x,y,z(mm), az, el(radians)]
Trans.ElementPos(:,1) = repmat(xs,1,elPerRow);
Trans.ElementPos(:,2) = ys; 
Trans.elementWidth = 0.8; % width in mm (spacing–kerf)

% Plot Element Arrangement
%scatter(Trans.ElementPos(:,1),Trans.ElementPos(:,2))

%% Default Sensitivity (using fake elements so irrelevant)
Theta = (-pi/2:pi/100:pi/2);
X = Trans.elementWidth*pi*sin(Theta);
Trans.ElementSens = abs(cos(Theta).*(sin(X)./X)); % [1x101 double] sens. curve for single element –pi/2to+pi/2

%% Element Mappnig
Trans.ConnectorES = (1:121)';

%% Optional Parameters
% bandwidth = 0.02; % fraction of Hz at -3dB for smart materials W821 - double check for -6dB as requested by Vera
% %Trans.Bandwidth = [0.8,1,2]; 
% load("DIYMk1Impedance.mat")
% Trans.impedance = DIYMk1Impedance; % complex single value or array of freq/value pairs
Trans.impedance = 6.8-1j*137; % complex single value or array of freq/value pairs
Trans.maxHighVoltage = 50;

%% Save
%save("Barney\Verasonics-Acoustic-Tweezer\TransducerData\PogoPinTestArray.mat","Trans")
save("3MHz2D_Trans.mat","Trans")

