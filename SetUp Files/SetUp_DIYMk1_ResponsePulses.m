clear all

% Similar to SetUp_PogoPinTest but with a receive buffer on the first
% transmit


%% Generate Resource
Resource.Parameters.numTransmit = 121; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.System.UTA = '160-SH';

% Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Media.MP(1,:) = [0,0,100,1.0]; % [x, y, z, reflectivity]

%% Generate Trans
load DIYMk1Trans.mat % need to generate

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
surface_depth = 50e-3;

%% Generate TW
nHalfCycles = 2;
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,nHalfCycles,1]; % A, B, C, D
TW(1).equalize = 1;

%% Specify TX structure array. 
TX.waveform = 1; % use 1st TW structure.
% TX.FocalPtMm = [0,0,surface_depth]*1e3;
TX.Origin = [0,0,0];
TX.Apod = ones(1,Trans.numelements);
TX.Delay = computeTXDelays(TX);

TPC(1).hv = 5;

%% Specify sequence events.
Event(1).info = 'Acquisition'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = [1,2]; % transfer data to host
%  SeqControl(1).command = 'transferToHost';
 SeqControl(1).command = 'triggerOut';
 SeqControl(2).command = 'timeToNextAcq';
 SeqControl(2).argument = 50; % us pause between pulses
 SeqControl(3).command = 'jump';
 SeqControl(3).argument = 1;
 SeqControl(3).condition = 'exitAfterJump';

Event(2).info = 'Acquisition'; 
Event(2).tx = 1; % use 1st TX structure.
Event(2).rcv = 0; 
Event(2).recon = 0; % no reconstruction.
Event(2).process = 0; % no processing
Event(2).seqControl = [1,2,3]; % transfer data to host

%% Save all the structures to a .mat file.
save('Verasonics-Acoustic-Tweezer\Data Files\Rx_Repeat.mat'); 