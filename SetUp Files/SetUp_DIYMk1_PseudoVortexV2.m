clear all

% Simple plane wave generation for PogoPin testing

%% Generate Resource
Resource.Parameters.numTransmit = 121; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

Resource.System.UTA = '160-SH';

%% Generate Trans
load DIYMk1Trans % Load transducer model

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

%% Generate TW
nHalfCycles = 20;
TW(1).type = 'parametric';
TW(1).Parameters = [1.05,1,nHalfCycles,1]; % A, B, C, D
TW(1).equalize = 0;

%% Set Transmit Power
TPC(1).maxHighVoltage = 20; % Set max voltage

%% Specify TX structure array.
TTNB = 20; % us
r = 10; % Default radius (to be modified via GUI)

% Calculate the duty cycle of the sequence
period = 1 / (Trans.frequency * 1e6); %in seconds
dutyCycle = ((nHalfCycles/2) * period)/(TTNB*1e-6); % Duty cycle calculation
fprintf('Duty cycle: %.2f%%\n', dutyCycle * 100);

[TX, nFrames] = genTX(TTNB, r);

%% Specify sequence events.
SeqControl = genSeqControl(TTNB);
Event = genEvent(nFrames);

%% Save all the structures to a .mat file.
save('Verasonics-Tatsuki\Sequences\DIYMk1_PseudoVortex.mat');

%% Functions

function [TX, nFrames] = genTX(TTNB, r)

    Trans = evalin('base','Trans');

    SequenceLength = 1; %s
    tPerFrame = (TTNB*1e-6);
    nFrames = ceil(SequenceLength/(TTNB*1e-6));
    disp(['Gnerating ',num2str(nFrames),' frames...'])

    % Dynamic Focal Points
    fPlane = 68; % mm

    angles = linspace(0,2*pi,nFrames);
    fpoints = zeros(nFrames,3);
    fpoints(:,1) = r*cos(angles);
    fpoints(:,2) = r*sin(angles);
    fpoints(:,3) = fPlane;

    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,nFrames); 
    
    for i = 1:nFrames
        TX(i).FocalPtMm = fpoints(i,:);
        TX(i).Delay = computeTXDelays(TX(i));
    end
end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command = 'triggerOut';
    SeqControl(2).command = 'timeToNextAcq';
    SeqControl(2).argument = TTNB;
    SeqControl(3).command = 'jump';
    SeqControl(3).argument = 1;
    SeqControl(3).condition = 'exitAfterJump';
end

function Event = genEvent(nFrames)
    n = 1;
    for i = 1:nFrames
        Event(n).info = 'TX';
        Event(n).tx = i;
        Event(n).rcv = 0;
        Event(n).recon = 0;
        Event(n).process = 0;
        Event(n).seqControl = [1,2]; 
        n = n + 1;
    end
    Event(n).info = 'Check MATLAB';
    Event(n).tx = nFrames;
    Event(n).rcv = 0;
    Event(n).recon = 0;
    Event(n).process = 0;
    Event(n).seqControl = [1,2,3]; 
end
