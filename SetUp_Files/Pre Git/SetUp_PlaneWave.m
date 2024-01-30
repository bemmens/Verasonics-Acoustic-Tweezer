clear all

% Specify system parameters
Resource.Parameters.numTransmit = 128; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
%Resource.Parameters.fakescanhead = 1;

% Specify Trans structure array.
Trans.name = 'L11-5v'; 
Trans.frequency = 7.6; % not needed if using default center frequency 
Trans = computeTrans(Trans); % L11-5v transducer is 'known' transducer.

% Specify Resource buffers.
Resource.RcvBuffer(1).datatype = 'int16'; 
Resource.RcvBuffer(1).rowsPerFrame = 1; % this allows for 1/4 maximum range
Resource.RcvBuffer(1).colsPerFrame = 1; 
Resource.RcvBuffer(1).numFrames = 1; % minimum size is 1 frame.BR

% Specify Transmit waveform structure. 
TW(1).type = 'parametric'; 
TW(1).Parameters = [7.6,1,25,1]; % A, B, C, D

% Specify TX structure array. 
TX(1).waveform = 1; % use 1st TW structure.
TX(1).focus = 0; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
% TX(1).FocalPt = (x,y,z) location in wavelengths
% TX(1).FocalPtMm = (x,y,z) location in mm
TX(1).Steer = [0,0]; 
TX(1).Origin = 0;
TX(1).Apod = ones(1,Trans.numelements); 
TX(1).Delay = computeTXDelays(TX(1)); 

% Specify sequence events.
Event(1).info = 'Acquire RF Data.'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = 1; % transfer data to host
 SeqControl(1).command = 'timeToNextAcq';
 SeqControl(1).argument = 50000; % 50 ms pause between pulses
 SeqControl(2).command = 'jump'; 
 SeqControl(2).argument = 1;

% Save all the structures to a .mat file.
save('PlaneWave'); 
