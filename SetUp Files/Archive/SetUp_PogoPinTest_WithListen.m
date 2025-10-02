clear all

% Similar to SetUp_PogoPinTest but with a receive buffer on the first
% transmit


%% Generate Resource
Resource.Parameters.numTransmit = 9; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

%% Generate Trans
load PogoPinTestArray % need to generate

%% Recieve Structures
Resource.Parameters.numRcvChannels = 9;

% Specify Resource buffers.
Resource.RcvBuffer(1).datatype = 'int16'; 
Resource.RcvBuffer(1).rowsPerFrame = 2048; % allows for max depth of 256 wls
Resource.RcvBuffer(1).colsPerFrame = 9; % see text below
Resource.RcvBuffer(1).numFrames = 1; % minimum size is 1 frame.

% Specify TGC Waveform structure.
TGC(1).CntrlPts = [500,590,650,710,770,830,890,950]; 
TGC(1).rangeMax = 200; 
TGC(1).Waveform = computeTGCWaveform(TGC);

% Specify Receive structure array -
Receive(1).Apod = ones(1, 9); 
Receive(1).startDepth = 0; 
Receive(1).endDepth = 200; 
Receive(1).TGC = 1; % Use the first TGC waveform defined above
Receive(1).mode = 0; 
Receive(1).bufnum = 1; 
Receive(1).framenum = 1; 
Receive(1).acqNum = 1; 
Receive(1).sampleMode = 'NS200BW'; 
Receive(1).LowPassCoef = []; 
Receive(1).InputFilter = [];

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

%% Generate TW
pulseLength = 100; % ms
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
Event(1).info = '1st TX'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 1; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = 1; % transfer data to host
 SeqControl(1).command = 'timeToNextAcq';
 SeqControl(1).argument = 50000; % 50 ms pause between pulses

for n = 2:1000
    Event(n).info = 'nth TX'; 
    Event(n).tx = 1; % use 1st TX structure.
    Event(n).rcv = 0; 
    Event(n).recon = 0; % no reconstruction.
    Event(n).process = 0; % no processing
    Event(n).seqControl = 1; % transfer data to host
        SeqControl(1).command = 'timeToNextAcq';
        SeqControl(1).argument = 50000; % 50 ms pause between pulses
end

Event(n+1).info = 'Check GUI'; 
Event(n+1).tx = 0; % use 1st TX structure.
Event(n+1).rcv = 0; 
Event(n+1).recon = 0; % no reconstruction.
Event(n+1).process = 0; % no processing
Event(n+1).seqControl = [1,2]; % transfer data to host
    SeqControl(1).command = 'timeToNextAcq';
    SeqControl(1).argument = 50000; % 50 ms pause between pulses
    SeqControl(2).command = 'jump'; 
    SeqControl(2).argument = 1;
    SeqControl(2).condition = 'exitAfterJump';

%% Save all the structures to a .mat file.
save('Verasonics-Acoustic-Tweezer\Data Files\PogoPinTest.mat'); 