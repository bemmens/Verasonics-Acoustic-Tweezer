clear all

% Simple plane wave generation for PogoPin testing

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

%%
TPC(1).maxHighVoltage = 8; % Set max voltage to 30V

%% Specify TX structure array.
TTNB = 20; % us

dutyCycle = (TTNB - nHalfCycles/2)/TTNB;
fprintf('Duty cycle: %e\n', dutyCycle)

% fieldData = load('line_sweep');
% fieldData = load('circle_sweep');
fieldData = load('focus_merging_sweep');
frames = fieldData.output_store;
nFrames = size(frames,2);

[TX,EventsPerFrame] = genTX(TTNB,frames);

%% Specify sequence events.
SeqControl = genSeqControl(TTNB);

Event = genEvent(nFrames,EventsPerFrame);

%% Save all the structures to a .mat file.
save('Verasonics-Tatsuki\Sequences\DIYMk1_PhaseVideo.mat');

%save('C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\DIYMk1Test.mat');

%%

function [TX,EvenetsPerFrame] = genTX(TTNB,frames)

    Trans = evalin('base','Trans');
    nFrames = size(frames,2);

    SequenceLength = 1; %s
    tPerFrame = SequenceLength/nFrames;
%     refreshRate = 200; %Hz
%     tPerFrame = 1/refreshRate;
    EvenetsPerFrame = tPerFrame/(TTNB*1e-6);
    disp("Sequence Length (seconds):")
    disp(tPerFrame*nFrames)
    %disp(EvenetsPerStep*npoints)
    
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,nFrames); % matrix shape  
    
    
    for i = 1:nFrames
        TX(i).Delay = frames(:,i)';
%         TX(i).FocalPtMm = [-4+2*i 0 75];
%         TX(i).Delay = computeTXDelays(TX(i));
    end

end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command = 'triggerOut';

    SeqControl(2).command = 'timeToNextAcq';
    SeqControl(2).argument = TTNB; % us pause between pulses

    SeqControl(3).command = 'jump';
    SeqControl(3).argument = 1;
    SeqControl(3).condition = 'exitAfterJump';
end

function Event = genEvent(nFrames,EventsPerFrame)

    n=1;
    
    for i = 1:nFrames

        for j = 1:EventsPerFrame
%             disp('next')
            Event(n).info = 'TX';
            Event(n).tx = i; % use 1st TX structure.
            Event(n).rcv = 0;
            Event(n).recon = 0; % no reconstruction.
            Event(n).process = 0; % no processing
            Event(n).seqControl = [1,2]; %
            n = n + 1;
        end
    end
    
    Event(n).info = 'Check MatLab';
    Event(n).tx = nFrames; % use 1st TX structure.
    Event(n).rcv = 0;
    Event(n).recon = 0; % no reconstruction.
    Event(n).process = 0; % no processing
    Event(n).seqControl = [1,2,3]; % transfer data to host
end

