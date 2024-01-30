clear all

% Specify system parameters
Resource.Parameters.numTransmit = 1; % no. of transmit channels
Resource.Parameters.connector = 3; % trans. connector to use
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resource.Parameters.fakescanhead = 1;
Resource.Parameters.speedOfSound = 1481;

% Specify Trans structure array.
Trans.name = 'Oscilliscope'; 
Trans.id = -1;
Trans.units = 'mm';
Trans.frequency = 5;
Trans.wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6);
Trans.type = 0;
Trans.numelements = 1;
Trans.ElementPos = [0,0,0];
Trans.elementWidth = 1;
Trans.ElementSens = BeamPattern(Trans.elementWidth*1e-3,Trans.wavelength); % unit sens. curve
%Trans.ConnectES = 1;
Trans.connType = -1; % automatically detect UTA Module type
Trans.spacing = 0;
Trans.maxHighVoltage = 6;

% Specify Transmit waveform structure. 
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,5,-1]; % A, B, C, D
TW(2).type = 'parametric'; 
TW(2).Parameters = [Trans.frequency,1,10,-1]; % A, B, C, D

% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
TX(1).focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
TX(1).Steer = [0,0]; 
TX(1).Origin = 0;
TX(1).Apod = ones(1,Trans.numelements); 
TX(1).Delay = 0; 

TX(2).waveform = 2; % use 1st TW structure.
TX(2).focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
TX(2).Steer = [0,0]; 
TX(2).Origin = 0;
TX(2).Apod = ones(1,Trans.numelements); 
TX(2).Delay = 0; 

% Specify sequence events.

Event(1).info = 'Acquire RF Data.'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
%(1).seqControl = [1]; % transfer data to host
 %SeqControl(1).command = 'timeToNextAcq';
 %SeqControl(1).argument = 10; % 10us pause between pulses

for eventN = 2:3
    Event(eventN).info = 'Pulse Train'; 
    Event(eventN).tx = 2; 
    Event(eventN).rcv = 0; 
    Event(eventN).recon = 0; % no reconstruction.
    Event(eventN).process = 0; % no processing
end

eventN = eventN + 1;

Event(eventN).info = 'Check for GUI update'; 
Event(eventN).tx = 0; 
Event(eventN).rcv = 0; 
Event(eventN).recon = 0; % no reconstruction.
Event(eventN).process = 0; % no processing
Event(eventN).seqControl = [1]; 
 %SeqControl(4).command = 'returnToMatlab';
 SeqControl(1).command = 'jump'; 
 SeqControl(1).argument = 1;

% Save all the structures to a .mat file.
save('Barney/data_files/SingleTranTest'); 
