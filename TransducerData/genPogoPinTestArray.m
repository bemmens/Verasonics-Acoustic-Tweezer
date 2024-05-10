clear all
Trans.name = 'PogoPinTestArray'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.frequency = 1;

Trans.type = 2;
elPerRow = 3;
Trans.numelements = elPerRow^2;

%% Generate Element Positions
% Places all elements on a grid with 0,0 at the centre of the array.
pitch = 3.1;
xs = (-(elPerRow-1)/2:(elPerRow-1)/2)*pitch;
ys = reshape(repmat(-xs, elPerRow, 1), 1, []);

Trans.ElementPos = zeros(Trans.numelements,5); %[nx5 double] -> [x,y,z(mm), az, el(radians)]
Trans.ElementPos(:,1) = repmat(xs,1,elPerRow);
Trans.ElementPos(:,2) = ys; 

%% ctd.
Trans.elementWidth = 3; % width in mm (spacing–kerf)

%% Default Sensitivity (using fake elements so irrelevant)
Theta = (-pi/2:pi/100:pi/2);
X = Trans.elementWidth*pi*sin(Theta);
Trans.ElementSens = abs(cos(Theta).*(sin(X)./X)); % [1x101 double] sens. curve for single element –pi/2to+pi/2

%Trans.ConnectorES   %[nx1 double] EL to ES map (see text below & sec.2.2.1) - UNSPECIFIED => Default 1->1 map
Trans.connType = 12;     %double % specifies type of Probe connector (see text)

%% Optional Parameters
bandwidth = 0.02; % fraction of Hz at -3dB for smart materials W821 - double check for -6dB as requested by Vera
%Trans.Bandwidth = [0.8,1,2]; 
Trans.impedance = readmatrix("PogoPin1ResReact.xlsx"); %complex single value or array of freq/value pairs
Trans.maxHighVoltage = 50;

%% Save
save("Barney\Verasonics-Acoustic-Tweezer\TransducerData\PogoPinTestArray.mat","Trans")