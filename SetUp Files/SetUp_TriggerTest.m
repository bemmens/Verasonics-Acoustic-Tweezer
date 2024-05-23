clear all

% Simple plane wave generation for PogoPin testing

%% Generate Resource
Resource.Parameters.numTransmit = 9; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

Resource.System.UTA = '160-SH';

%% Generate Trans
load PogoPinTestArray % need to generate

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

%% Generate TW
pulseLength = 100; % us
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,0.9,nHalfCycles,1]; % A, B, C, D
TW(1).equalize = 0;

%% Specify TX structure array. 
TX.waveform = 1; % use 1st TW structure.
TX.focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
TX.Steer = [0,0]; 
TX.Origin = [0,0,0];
TX.Apod = ones(1,Trans.numelements);
TX.Apod(5) = 0;
TX.Delay = computeTXDelays(TX); 

%% Specify sequence events.
Event(1).info = 'Start Trigger'; 
Event(1).tx = 0; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = [1,2]; % transfer data to host
 SeqControl(1).command = 'triggerOut';
 SeqControl(2).command = 'noop';
 SeqControl(2).argument = 500; % 0.5 ms before pulses
 
Npulses = 10;
for n = 2:2+Npulses
    Event(n).info = 'TX'; 
    Event(n).tx = 0; % use 1st TX structure.
    Event(n).rcv = 0; 
    Event(n).recon = 0; % no reconstruction.
    Event(n).process = 0; % no processing
    Event(n).seqControl = [1,6]; % transfer data to host
        SeqControl(1).command = 'triggerOut';
        SeqControl(3).command = 'timeToNextAcq';
        SeqControl(3).argument = 5000; % 5 ms pause between pulses
        SeqControl(6).command = 'noop';
        SeqControl(6).argument = 1000; % 1 ms pause between pulses
end

Event(n+1).info = 'Check MatLab'; 
Event(n+1).tx = 0; % use 1st TX structure.
Event(n+1).rcv = 0; 
Event(n+1).recon = 0; % no reconstruction.
Event(n+1).process = 0; % no processing
Event(n+1).seqControl = [4]; % transfer data to host
    SeqControl(4).command = 'jump'; 
    SeqControl(4).argument = 1;
    SeqControl(4).condition = 'exitAfterJump';
    SeqControl(5).command = 'returnToMatlab'; 

%% Save all the structures to a .mat file.
%save('Barney\Verasonics-Acoustic-Tweezer\Data Files\PogoPinTest.mat'); 
save('Verasonics-Acoustic-Tweezer\Data Files\TriggerTest.mat'); 