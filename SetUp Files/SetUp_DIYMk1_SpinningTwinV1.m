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

% GUI Variables
SpinPeriod = 0.0003; % seconds
FocalPtMm = [0 0 1e3]; 

% Calculate the duty cycle of the sequence
period = 1 / (Trans.frequency * 1e6); %in seconds
dutyCycle = ((nHalfCycles/2) * period)/(TTNB*1e-6); % Duty cycle calculation
fprintf('Duty cycle: %.2f%%\n', dutyCycle * 100);

[TX, nFrames,angles,twinPhases] = genTX(TTNB, SpinPeriod, FocalPtMm);

%% Specify sequence events.
SeqControl = genSeqControl(TTNB);
Event = genEvent(nFrames);

%% UI Controls

xlim = 10;
ylim = xlim;
zlim = 100;

% X-Axis Slider for TX Focal Point
UI(1).Control = {'UserB5', 'Style', 'VsSlider', ...
    'Label', 'X [mm]', ...
    'SliderMinMaxVal', [-xlim, xlim, 0], ... % X range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.2f'};
UI(1).Callback = @updateFocalPointX;

% Y-Axis Slider for TX Focal Point
UI(2).Control = {'UserB4', 'Style', 'VsSlider', ...
    'Label', 'Y [mm]', ...
    'SliderMinMaxVal', [-ylim, ylim, 0], ... % Y range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.2f'};
UI(2).Callback = @updateFocalPointY;

% Z-Axis Slider for TX Focal Point
UI(3).Control = {'UserB3', 'Style', 'VsSlider', ...
    'Label', 'Z [mm]', ...
    'SliderMinMaxVal', [0, zlim, 50], ... % Z range: 20mm to 100mm, default 50
    'SliderStep', [0.01, 0.1], ...
    'ValueFormat', '%3.2f'};
UI(3).Callback = @updateFocalPointZ;

% Spin Period
UI(4).Control = {'UserB1', 'Style', 'VsSlider', ...
    'Label', 'Period [ms]', ...
    'SliderMinMaxVal', [0.00001, 0.5, 0.01]*1000, ... % [min,max,step]
    'SliderStep', [0.01, 0.1], ...
    'ValueFormat', '%5.1f'};
UI(4).Callback = @updatePeriod;

%% Save all the structures to a .mat file.
name = 'DIYMk1_SpinTwinV1';
save(strcat('/Users/gv19838/Documents/Vantage-4.9.7-2505271400/Verasonics-Acoustic-Tweezer/Data Files/',name,'.mat'));
disp(name)

%% Functions

function updateFocalPointX(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    SpinPeriod = evalin('base','SpinPeriod');
    % Update only the X coordinate of the focal point
    FocalPtMm(1) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(SpinPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end

function updateFocalPointY(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    SpinPeriod = evalin('base','SpinPeriod');
    % Update only the Y coordinate of the focal point
    FocalPtMm(2) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(SpinPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end

function updateFocalPointZ(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    SpinPeriod = evalin('base','SpinPeriod');
    % Update only the Z coordinate of the focal point
    FocalPtMm(3) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(SpinPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end

function updatePeriod(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    assignin('base', 'SpinPeriod', UIValue/1000);
    % Update system
    updateSequence(UIValue/1000, FocalPtMm);
    % Print new Sequence Parameters
    disp(strcat('Current Spin Period:',{' '} ,num2str(UIValue),"ms"))
end


function [TX, nFrames,angles,twinPhases] = genTX(TTNB, SpinPeriod, FocalPtMm)

    Trans = evalin('base','Trans');

    nFrames = ceil(SpinPeriod/(TTNB*1e-6));
    disp(['nFrames: ',num2str(nFrames)])

    % generate List of angles
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'FocalPtMm', FocalPtMm, ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,nFrames); 

    angles = linspace(0,2*pi,nFrames);
    twinPhases = (Trans.ElementPos(:,2) > tan(angles).*Trans.ElementPos(:,1)) .* 0.5; % identity matrix to check if whcih side of rotating line element is on
    
    for i = 1:nFrames
        if pi/2<angles(i) && angles(i)<=3*pi/2               % make sure that the twin trap is oriented the right way
            TX(i).Delay = computeTXDelays(TX(i)) + twinPhases(:,i)';
        else
            TX(i).Delay = computeTXDelays(TX(i)) - twinPhases(:,i)' + 0.5; 
        end
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
                      'rcv', 0, ...
                      'recon', 0, ...
                      'process', 0, ...
                      'seqControl', [1,2]), ...
                      1,nFrames);

    Event(nFrames).seqControl = [1,2,3];

    n = 1;
    for i = 1:nFrames
        Event(n).tx = i;
        n = n+1;
    end

end

function [Event,TX] = updateSequence(SpinPeriod, FocalPtMm)
    % Gen new TX and Events
    TTNB = evalin('base','TTNB');
    [TX, nFrames] = genTX(TTNB, SpinPeriod, FocalPtMm);
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

end
