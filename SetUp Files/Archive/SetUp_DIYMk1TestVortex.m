clear all

% Simple focussedmvortex generation for PogoPin testing

%% Generate Resource
Resource.Parameters.numTransmit = 121; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

Resource.System.UTA = '160-SH';

%% Generate Trans
load DIYMk1Trans % need to generate

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

%% Generate TW
%pulseLength = 10; % us
%nHalfCycles = int32(2*pulseLength*Trans.frequency);
nHalfCycles = 20;
TW(1).type = 'parametric'; 
TW(1).Parameters = [1.05,1,nHalfCycles,1]; % A, B, C, D
TW(1).equalize = 0;

%% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
%TX.focus = 10; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
%TX.Steer = [0,0]; 
TX(1).FocalPtMm = [0,0,67]; %[1x3 double] FocalPt in mm instead of wavelengths
TX(1).Origin = [0,0,0];
TX(1).Apod = ones(1,Trans.numelements);
[RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
TX.Delay = computeTXDelays(TX) + + RH_VortexDelay'; 

%% Specify sequence events.

TTNB = 20; % us
Event(1).info = 'Start Trigger'; 
Event(1).tx = 0; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = [1,2]; % transfer data to host
 SeqControl(1).command = 'triggerOut';
 SeqControl(2).command = 'noop';
 SeqControl(2).argument = TTNB; % us pause between sequences

Npulses = 10;
i = 2;
for n = 1:2*Npulses
    Event(i).info = 'TX'; 
    Event(i).tx = 1; % use 1st TX structure.
    Event(i).rcv = 0; 
    Event(i).recon = 0; % no reconstruction.
    Event(i).process = 0; % no processing
    Event(i).seqControl = [1,3]; % transfer data to host
        SeqControl(3).command = 'timeToNextAcq';
        SeqControl(3).argument = TTNB; % us pause between pulses

    i = i+1;

    Event(i).info = 'TX'; 
    Event(i).tx = 2; % use 1st TX structure.
    Event(i).rcv = 0; 
    Event(i).recon = 0; % no reconstruction.
    Event(i).process = 0; % no processing
    Event(i).seqControl = [1,3]; % transfer data to host

    i = i+1;

end

Event(i).info = 'Check MatLab'; 
Event(i).tx = 0; % use 1st TX structure.
Event(i).rcv = 0; 
Event(i).recon = 0; % no reconstruction.
Event(i).process = 0; % no processing
Event(i).seqControl = [1,4]; % transfer data to host
    SeqControl(4).command = 'jump'; 
    SeqControl(4).argument = 1;
    SeqControl(4).condition = 'exitAfterJump';
    SeqControl(5).command = 'returnToMatlab'; 

%% Save all the structures to a .mat file.
save('Verasonics-Acoustic-Tweezer\Data Files\DIYMk1TestVortex.mat'); 
%save('C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\DIYMk1Test.mat'); 