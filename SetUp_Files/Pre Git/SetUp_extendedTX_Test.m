clear variables

% Specify system parameters
Resource.Parameters.numTransmit = 1; % no. of transmit channels
Resource.Parameters.Connector = 1; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
%Resouce.Parameters.verbose = 2;
Resource.Parameters.fakescanhead = 1;

% Specify Trans structure array.
Trans.name = 'Oscilliscope'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.frequency = 1;
Trans.impedance = 1e6;
Trans.type = 0;
Trans.numelements = 1;
Trans.ElementPos = [0,0,0];
Trans.elementWidth = 1;
Trans.ElementSens = ones(1,101); % unit sens. curve
%Trans.ConnectES = 1;
%Trans.connType = 0; % automatically detect UTA Module type
Trans.spacing = 0;
Trans.maxHighVoltage = 6;

lambda_mm = Resouce.Parameters.speedOfSound*1e3/(Trans.frequency*1e6);

%TPC Settings
%TPC(5).maxHighVoltage = 80;
TPC(5).highVoltageLimit = 50;

% Specify Transmit waveform structure. 
pulseLength = 20; % ms
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,nHalfCycles,1]; % A, B, C, D
TW(1).equalize = 0;

% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
TX(1).focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
TX(1).Steer = [0,0]; 
TX(1).Origin = 0;
TX(1).Apod = ones(1,Trans.numelements); 
TX(1).Delay = 0; 

% Sequence Controls
n = 1;
nTransmitsPerCharge = 1;

SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 5;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'noop';
SeqControl(2).argument = 50000 ;% 10 ms

SeqControl(3).command = 'timeToNextEB';
SeqControl(3).argument = 100; % us pause between pulses (10 is minimum specifiable)

SeqControl(4).command = 'returnToMatlab';

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 1;

SeqControl(6).command = 'setTPCProfile';
SeqControl(6).argument = 1;
SeqControl(6).condition = 'immediate';

% Specify Event structure arrays.
% Push % For any script using multiple TPC profiles, and especially any
% script using Profile 5 for Push transmit, the script must explicitly
% specify an initial profile at the beginning of the script, prior to any
% transmit events.  This is to prevent the script from 'inheriting'
% whatever TPC Profile was in effect when some previous script was
% terminated.
Event(n).info = 'Engage Extended Transmit'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 1; 
n = n+1;

% Specify sequence events.
Event(n).info = 'Charge Capacitor'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 2; 
n = n+1;


for n = n:n+nTransmitsPerCharge-1
    Event(n).info = 'Transmit'; 
    Event(n).tx = 1; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = 3; 
    n = n+1;
end

Event(n).info = 'Check for GUI update'; 
Event(n).tx = 0; 
Event(n).rcv = 0; 
Event(n).recon = 0; % no reconstruction.
Event(n).process = 0; % no processing
Event(n).seqControl = [4,5]; 


% Save all the structures to a .mat file.
save('Barney/data_files/extendedTX_Test'); 
disp('KerCHOW!')
EventAnalysisTool
%VSX
