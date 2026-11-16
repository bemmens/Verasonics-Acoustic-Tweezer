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
load 3MHz2D_Trans.mat % need to generate

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

%% Recieve Structures
Resource.Parameters.numRcvChannels = 121;
nCh = Resource.Parameters.numRcvChannels;

% Specify Resource buffers.
Resource.RcvBuffer(1).datatype = 'int16'; 
% Note: Sample rate is 4xTrans.frequency by default
Resource.RcvBuffer(1).rowsPerFrame = 1*512; % samples stored per acquisition (eg: 2048 -> measures for 512 wavelengths -> max imaging depth of 256 wavelngths)
Resource.RcvBuffer(1).colsPerFrame = 121; % num channels
Resource.RcvBuffer(1).numFrames = 1; % minimum size is 1 frame.

% Specify TGC Waveform structure.
TGC(1).rangeMax = 200;
TGC(1).CntrlPts = [500,590,650,710,770,830,890,950];  
TGC(1).Waveform = computeTGCWaveform(TGC);

% Specify Receive structure array -
Receive(1).Apod = ones(1, nCh); 
Receive(1).startDepth = 0;  
% Receive(1).endDepth = int16(surface_depth*1.5/wavelength); % in wavelengths (distance from source to be imaged)
Receive(1).endDepth =  1*64; % in wavelengths (distance from source to be imaged)
Receive(1).TGC = 1; 
Receive(1).mode = 0; 
Receive(1).bufnum = 1; 
Receive(1).framenum = 1; 
Receive(1).acqNum = 1; 
Receive(1).sampleMode = 'NS200BW'; % Default

%% Specify sequence events.
Event(1).info = 'Acquisition'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 1; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = 1; % transfer data to host
 SeqControl(1).command = 'transferToHost';

%% Save all the structures to a .mat file.
save('Verasonics-Acoustic-Tweezer\Data Files\3MHz_Rx.mat'); 