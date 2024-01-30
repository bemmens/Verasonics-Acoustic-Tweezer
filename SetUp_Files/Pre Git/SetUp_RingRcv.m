clear variables

% Specify system parameters
Resource.Parameters.numTransmit = 32; % no. of transmit channels
Resource.Parameters.numRcvChannels = 32;
Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
%Resouce.Parameters.verbose = 2;
%Resource.Parameters.fakescanhead = 1;


% Specify Trans structure array.
load Trans_Ring

lambda_mm = Resouce.Parameters.speedOfSound*1e3/(Trans.frequency*1e6);

Trans.ElementPos(:,5) = zeros(32,1);

% Specify Resource buffers.
Resource.RcvBuffer(1).datatype = 'int16'; 
Resource.RcvBuffer(1).rowsPerFrame = 2048; % allows for max depth of 256 wls
Resource.RcvBuffer(1).colsPerFrame = 32; % see text below
Resource.RcvBuffer(1).numFrames = 1; % minimum size is 1 frame.

% Specify TGC Waveform structure.
TGC(1).CntrlPts = [500,590,650,710,770,830,890,950]; 
TGC(1).rangeMax = 200; 
TGC(1).Waveform = computeTGCWaveform(TGC);

% Specify Receive structure array -
Receive(1).Apod = ones(1, 32); 
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

%spec focal dist in mm
%focalDist_mm = 22;
%focalDist_nW = focalDist_mm*mmToNW;
PDepth_mm = 50;
PDepth_nW = PDepth_mm/lambda_mm;

% Specify PData structure array.
PData.PDelta = [0.015,0.015,0.15]; % x, y and z wavelengths per pixel
PData.Size(1) = ceil(0.0625*Trans.diameter/PData.PDelta(1));
PData.Size(2) = PData.Size(1);
PData.Size(3) = ceil(PDepth_nW/PData.PDelta(3)); 
% PData.Origin is the location [x,y,z] of the upper lft corner of the array.
PData.Origin = [-PData.Size(1)*PData.PDelta(1)/2,PData.Size(2)*PData.PDelta(2)/2,0];

%TPC Settings
TPC(5).maxHighVoltage = 50;
%TPC(5).highVoltageLimit = 50;

% Specify Transmit waveform structure. 
pulseLength = 20; % ms
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,2,1]; % A, B, C, D
TW(1).equalize = 0;

%TW(2).type = 'states';

% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
TX(1).focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
%TX(1).focus = 0;
% TX(1).FocalPt = (x,y,z) location in wavelengths
% TX(1).FocalPtMm = [1,0,5] ; %location in mm
TX(1).Steer = [0,0]; 
TX(1).Origin = [0,0,0];
TX(1).Apod = ones(1,Trans.numelements); 
%TX(1).Apod = zeros(1,Trans.numelements);
%TX(1).Apod(1) = 1;

[DelayVector,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
%DelayVector = zeros(Trans.numelements,1);

TX(1).Delay = computeTXDelays(TX(1)) + DelayVector'; 
%TX(1).Delay = zeros(1,32);

TX.TXPD = computeTXPD(TX, PData);

SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 5;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'noop';
SeqControl(2).argument = 50000 ;% 10 ms

SeqControl(3).command = 'timeToNextEB';
SeqControl(3).argument = 360; % us pause between pulses (10 is minimum specifiable)

SeqControl(4).command = 'returnToMatlab';

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 2;

SeqControl(6).command = 'setTPCProfile';
SeqControl(6).argument = 1;
SeqControl(6).condition = 'immediate';

SeqControl(7).command = 'transferToHost';

% Specify Event structure arrays.
n = 1;

% Push % For any script using multiple TPC profiles, and especially any
% script using Profile 5 for Push transmit, the script must explicitly
% specify an initial profile at the beginning of the script, prior to any
% transmit events.  This is to prevent the script from 'inheriting'
% whatever TPC Profile was in effect when some previous script was
% terminated.
Event(n).info = 'select TPC profile';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 6;
n = n+1;


% Specify sequence events.
Event(n).info = 'Charge Capacitor'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [2]; 
n = n+1;

Event(n).info = 'Engage Extended Transmit'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [1]; 
n = n+1;

nTransmitsPerCharge = 1;
for n = n:n+nTransmitsPerCharge-1
Event(n).info = 'Transmit and Recieve'; 
Event(n).tx = 1; 
Event(n).rcv = 1; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [3,7]; 
n = n+1;
end

Event(n).info = 'Check for GUI update'; 
Event(n).tx = 0; 
Event(n).rcv = 0; 
Event(n).recon = 0; % no reconstruction.
Event(n).process = 0; % no processing
Event(n).seqControl = [4,5]; 
n = n+1;



% Save all the structures to a .mat file.
save('Barney/data_files/RingRcv'); 
disp('KerCHOW!')
%EventAnalysisTool
%VSX
