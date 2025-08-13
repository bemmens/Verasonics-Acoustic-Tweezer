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
TW(1).Parameters = [1.05,1,nHalfCycles,1]; % MHz, PulseWidth, NHalfCycles,polarity
TW(1).equalize = 0;

%% Set Transmit Power
TPC(1).maxHighVoltage = 20; % Set max voltage

%% Specify TX structure array.
TTNB = 20; % us
r = 10; % [mm] Default radius (to be modified via GUI)
VortexPeriod = 0.01; % [s] Default

% Calculate the duty cycle of the sequence
period = 1 / (Trans.frequency * 1e6); %in seconds
dutyCycle = ((nHalfCycles/2) * period)/(TTNB*1e-6); % Duty cycle calculation
fprintf('Duty cycle: %.2f%%\n', dutyCycle * 100);

[TX, nFrames] = genTX(TTNB, r, VortexPeriod);

%% Specify sequence events.
SeqControl = genSeqControl(TTNB);
Event = genEvent(nFrames);

%% UI Control

% Radius
UI(1).Control = {'UserB1', 'Style', 'VsSlider', ...
    'Label', 'Vortex Radius', ...
    'SliderMinMaxVal', [0, 10, 1.48], ... % Radius range: 0mm to 10mm, default 1.48mm
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.0f'};
UI(1).Callback = @updateRadius;

% Vortex Period
UI(2).Control = {'UserB2', 'Style', 'VsSlider', ...
    'Label', 'Vortex Period', ...
    'SliderMinMaxVal', [0, 0.5, 0.01], ... % Radius range: 0mm to 10mm, default 1.48mm
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%5.3f'};
UI(2).Callback = @updatePeriod;

%% Save all the structures to a .mat file.
save('Verasonics-Tatsuki\Sequences\DIYMk1_PseudoVortex.mat');

%% Functions

function updateRadius(~, ~, UIValue)
    % Retrieve TX from the base workspace
    assignin('base', 'r', UIValue);
    % Update system
    updateTX(r);
end

function updatePeriod(~, ~, UIValue)
    % Retrieve TX from the base workspace
    assignin('base', 'VortexPeriod', UIValue);
    % Update system
    updateTX(r, VortexPeriod);
end

function [TX, nFrames] = genTX(r, VortexPeriod)

    Trans = evalin('base','Trans');
    TTNB = evalin('base','TTNB');

    nFrames = ceil(VortexPeriod/(TTNB*1e-6));
    disp(['Gnerating ',num2str(nFrames),' frames...'])

    % generate List of Focal Points
    fPlane = 50; % mm

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

    Event = repmat(struct('info', 'TX', ...
                      'tx', 1, ...
                      'rvc', 0, ...
                      'recon', 0, ...
                      'pocess', 0, ...
                      'SeqContol', [1,2]), ...
                      1,nFrames);

    Event(nFrames).seqControl = [1,2,3];

    n = 1;
    for i = 1:nFrames
        Event(n).tx = i;
    end

end

function [Event,TX] = updateSequence(r, VortexPeriod)
    % Gen new TX and Events
    [TX, nFrames] = genTX(r,VortexPeriod);
    Event = genEvent(nFrames);

    % Save updated TX back to base workspace
    assignin('base', 'TX', TX);
    assignin('base','Event',Event)

    % update&run
    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'SeqControl'};
    
    Control(2).Command = 'update&Run';
    Control(2).Parameters = {'TX'};
    
    Control(3).Command = 'update&Run';
    Control(3).Parameters = {'Event'};
    
    assignin('base', 'Control', Control);

    % Print new Sequence Parameters
    disp(['Current Vortex Radius: ', num2str(r),"mm"])
end
