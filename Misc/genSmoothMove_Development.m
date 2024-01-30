clear all
%format long 

load Trans_Ring
Resouce.Parameters.speedOfSound = 1481;
wavelength = Resouce.Parameters.speedOfSound/(Trans.frequency*1e6);

%Specify largest steering step
dr = wavelength/10;
if dr>wavelength/2
    disp('ERROR:dr too large!')
    DISP('-------------------')
end
H = 0.04;
%dTheta = x2theta(dr,H); % rad

% Specify current and target positions in mm
r0 = 0;
rTarget = 10; 

distance = (rTarget - r0)/1e3 ;%now to m
nLargestSteps = floor(distance/dr);
N = nLargestSteps+1;
drPrecisionStep = distance-(dr*nLargestSteps);
%drTotal = nLargestSteps*dr + drPrecisionStep;

%Specify list of ositions to move through
    % Includes r0 position (could be removed if move needs to be faster).
rs = dr*(0:N) + (r0/1000);
rs(N+1) = rTarget/1000;% x coords of 1st to last position
thetas = pi/2 - cart2pol(rs,H);

%% Generate TXs for move
naMove = length(thetas);
TX = repmat(struct('waveform', 1, ...
                   'Origin', zeros(1,3), ...
                   'focus', 0, ...
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,Trans.numelements), ...
                   'Delay', zeros(1,Trans.numelements)),...
                   1,2*na); % matrix shape  

[RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
LH_VortexDelay = flip(RH_VortexDelay);

for j = 1:na
    TX(j).Steer = [thetas(j),0];
    TX(j).Delay = RH_VortexDelay'; 
end
for j = na+1:(2*na)
    TX(j).Steer = [thetas(j-na),0];
    TX(j).Delay = LH_VortexDelay'; 
end

%% Specify Event Sequence
TTNB = 360e-6;
timePerLoc = 10e-3; %seconds
nTXPerLoc = ceil(timePerLoc/TTNB);
disp('Move Time:')
disp(timePerLoc*(N+1))

n = 1;
for i = 1:N+1
    for j = 1:nTXPerLoc
        Event(n).info = 'Transmit'; 
        Event(n).tx = i; 
        Event(n).rcv = 0; 
        Event(n).recon = 0; 
        Event(n).process = 0; 
        Event(n).seqControl = 3; 
        n = n+1;
        
        Event(n).info = 'Transmit'; 
        Event(n).tx = i+na; 
        Event(n).rcv = 0; 
        Event(n).recon = 0; 
        Event(n).process = 0; 
        Event(n).seqControl = 3; 
        n = n+1;
    end
end