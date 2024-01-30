clear all

Trans.name = 'Imasonic_1MHz_Ring'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.Bandwidth = [2,4]; 
Trans.frequency = 1;

Trans.type = 2;
Trans.numelements = 32;

% ----------- Generate Element Coordinates -------------

Ri = 24.5e-3/2;
Ro = 30.5e-3/2;
%Rc = sqrt((Ro^2 + Ri^2)/2); % geometric mean centre
Rc = (Ri+Ro) / 2;
nElements = 32;

c_water = 1481;
lambda_mm = c_water*1e3/(Trans.frequency*1e6);

elementSpacing_rad = 2*pi/nElements;

elementIds = 1:nElements;
elementCoordsCart = zeros(nElements,5); % x, y, elevation

for i = elementIds
    elementCoordsCart(i,5) = (i-1)*elementSpacing_rad;
    [elementCoordsCart(i,1),elementCoordsCart(i,2)] = pol2cart(elementCoordsCart(i,5),Rc);
end

% --------------------------


Trans.ElementPos = elementCoordsCart*1e3; % must be in mm
Trans.elementWidth = 2;
Trans.diameter = 2*Ro*1e3/lambda_mm; % wavelengths

%Theta = (-pi/2:pi/100:pi/2);
%X = Trans.elementWidth*pi*sin(Theta); % Default see Manual
%Trans.ElementSens = abs(cos(Theta).*(sin(X)./X));
Trans.ElementSens = BeamPattern(Trans.elementWidth*1e-3,lambda_mm*1e-3);

Trans.maxHighVoltage = 96;  % maxVpp/2

% ------------- Impedence Measurement -----------------------
%Trans.impedance = 94-40i;
load Imasonic1MHzRing32elmts_Impedence

Trans.impedance = [Imasonic1MHzRing32elmts.MHz,str2double(Imasonic1MHzRing32elmts.complexImdpedence)];

%Trans.ConnectES = 1:Trans.numelements ;
Trans.connType = -1; % automatically detect UTA Module type



Trans.spacingMm = 3; % centre to centre (ctc)
Trans.spacing = Trans.spacingMm/lambda_mm;

scatter(Trans.ElementPos(:,1),Trans.ElementPos(:,2))
pbaspect([1 1 1])

save("Barney/data_files/Trans_Ring")