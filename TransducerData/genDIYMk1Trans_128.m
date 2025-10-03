clear all
%%
Trans.name = 'DIYMk1'; 
Trans.id = -1;
Trans.connType = 12;
Trans.units = 'mm';
Trans.frequency = 1.05;

Trans.type = 2;
elPerRow = 11;
Trans.numelements = 128;

%% Generate Element Positions
% Places all elements on a grid with 0,0 at the centre of the array.
pitch = 3.1;
Trans.spacingMm = pitch;
wavelength =1481/(Trans.frequency*1e6); % in m
Trans.spacing = wavelength/(pitch*1e-3);
xs = (-(elPerRow-1)/2:(elPerRow-1)/2)*pitch;
xs = repmat(xs,1,elPerRow);
ys = (-(elPerRow-1)/2:(elPerRow-1)/2)*pitch;
ys = reshape(repmat(ys,elPerRow,1),1,elPerRow*elPerRow);

disp(size(xs))
disp(size(ys))

% Pad to reach 128 elements by appending zeros
padCount = Trans.numelements - numel(xs);
xs = [xs, zeros(1, padCount)];
ys = [ys, zeros(1, padCount)];

disp(size(xs))
disp(size(ys))

Trans.ElementPos = zeros(Trans.numelements,5); %[nx5 double] -> [x,y,z(mm), az, el(radians)]
Trans.ElementPos(:,1) = xs;
Trans.ElementPos(:,2) = ys; 
Trans.elementWidth = 3; % width in mm (spacing–kerf)

% Plot Element Arrangement
idx = (1:Trans.numelements)';
scatter(Trans.ElementPos(:,1),Trans.ElementPos(:,2),60,idx,'filled');
axis equal
colormap(jet(Trans.numelements));
colorbar('Ticks',linspace(1,Trans.numelements,5));
title('Element Positions Colored by Index');
xlabel('x (mm)'); 
ylabel('y (mm)');

%% Default Sensitivity (using fake elements so irrelevant)
Theta = (-pi/2:pi/100:pi/2);
X = Trans.elementWidth*pi*sin(Theta);
Trans.ElementSens = abs(cos(Theta).*(sin(X)./X)); % [1x101 double] sens. curve for single element –pi/2to+pi/2

%% Optional Parameters
bandwidth = 0.02; % fraction of Hz at -3dB for smart materials W821 - double check for -6dB as requested by Vera
%Trans.Bandwidth = [0.8,1,2]; 
load("DIYMk1Impedance.mat")
Trans.impedance = DIYMk1Impedance; % complex single value or array of freq/value pairs
Trans.maxHighVoltage = 50;

%% Save
%save("Barney\Verasonics-Acoustic-Tweezer\TransducerData\PogoPinTestArray.mat","Trans")
save("/Users/gv19838/Documents/Vantage-4.9.7-2505271400/Verasonics-Acoustic-Tweezer/TransducerData/DIYMk1Trans_128.mat","Trans")

