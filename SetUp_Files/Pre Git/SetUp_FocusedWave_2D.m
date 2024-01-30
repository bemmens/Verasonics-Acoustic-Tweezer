clear all

% Specify system parameters
Resource.Parameters.numTransmit = 121; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
Resouce.Parameters.verbose = 2;
%Resource.Parameters.fakescanhead = 1;

el_Stats = load("C:\Users\gv19838\OneDrive - University of Bristol\PhD\Verasonics\File_Share\Bristol arrays\Imasonic 2D matrix 121els 3.00MHz 1.00mm pitch.mat");
ElPos = zeros(121,5);
ElPos(:,1) = el_Stats.array.el_xc;
ElPos(:,2) = el_Stats.array.el_yc;

% Specify Trans structure array.
Trans.name = 'Immasonic_3MHz_121_2D'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.Bandwidth = [2,4]; 
Trans.frequency = 3.2;

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

%spec focal dist in mm
focalDist_mm = 10;
focalDist_nW = focalDist_mm*mmToNW;
PDepth_mm = 2*focalDist_mm;
PDepth_nW = PDepth_mm * mmToNW;

% Specify PData structure array.
PData.PDelta = [0.25,0.25,0.25]; % x, y and z pixel deltas (wavelengths)
PData.Size(1) = ceil(11*Trans.spacing/PData.PDelta(1));
PData.Size(2) = PData.Size(1);
PData.Size(3) = ceil(PDepth_nW/PData.PDelta(3)); % 2x focal distance
% PData.Origin is the location [x,y,z] of the upper lft corner of the array.
PData.Origin = [-PData.Size(1)*PData.PDelta(1)/2,PData.Size(2)*PData.PDelta(2)/2,0];

%TPC(5).highvoltagelimit = 10;

% Specify Transmit waveform structure. 
TW(1).type = 'parametric'; 
TW(1).Parameters = [7.6,1,50*2,1]; % A, B, C, D
TW(1).equalize = 0;

% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
TX(1).focus = focalDist_nW; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
% TX(1).FocalPt = (x,y,z) location in wavelengths
% TX(1).FocalPtMm = [1,0,5] ; %location in mm
%TX(1).Steer = [pi/32,0]; 
TX(1).Origin = [0,0,0];
TX(1).Apod = ones(1,Trans.numelements); 
TX(1).Delay = computeTXDelays(TX(1)); 
TX.TXPD = computeTXPD(TX, PData);

% Specify sequence events.
Event(1).info = 'Engage High Power'; 
Event(1).tx = 0;
Event(1).rcv = 0; 
Event(1).recon = 0; 
Event(1).process = 0; 
Event(1).seqControl = [1,2]; 
 SeqControl(1).command = 'setTPCProfile';
 SeqControl(1).argument = 5;
 SeqControl(1).condition = 'immediate';
 SeqControl(2).command = 'noop';
 SeqControl(2).argument = 50000 ;% 10 ms

Event(2).info = 'Transmit'; 
Event(2).tx = 1; % use 1st TX structure.
Event(2).rcv = 0; 
Event(2).recon = 0; % no reconstruction.
Event(2).process = 0; % no processing
Event(2).seqControl = [3]; 
 SeqControl(3).command = 'timeToNextAcq';
 SeqControl(3).argument = 10; % us pause between pulses (10 is minimum specifiable)

Event(3).info = 'Check for GUI update'; 
Event(3).tx = 0; 
Event(3).rcv = 0; 
Event(3).recon = 0; % no reconstruction.
Event(3).process = 0; % no processing
Event(3).seqControl = [4,5]; 
 SeqControl(4).command = 'returnToMatlab';
 SeqControl(5).command = 'jump'; 
 SeqControl(5).argument = 2;

disp('Hello?')
% Save all the structures to a .mat file.
save('Barney/FocusedWave2D'); 

