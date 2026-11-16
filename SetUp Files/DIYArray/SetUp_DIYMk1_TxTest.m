clear all

%% Generate Resource
Resource.Parameters.numTransmit = 128; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

Resource.System.UTA = '160-SH';

%% Generate Trans
load DIYMk1Trans_128 % need to generate

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
TPC(1).maxHighVoltage = 10; % Set max voltage

%% Specify TX structure array.
FocalPtMm = [0 0 50];
TX = genTX(FocalPtMm,0);

%% Specify sequence events.

TTNB = 20; % us

% Calculate the duty cycle of the sequence
period = 1 / (Trans.frequency * 1e6); %in seconds
dutyCycle = ((nHalfCycles/2) * period)/(TTNB*1e-6); % Duty cycle calculation
fprintf('Duty cycle: %.2f%%\n', dutyCycle * 100);

SeqControl = genSeqControl(TTNB);

TrapType = 6;
Event = genEvent(TrapType);

%% UI Control

xlim = 10;
ylim = xlim;
zlim = 100;

% X-Axis Slider for TX Focal Point
UI(1).Control = {'UserB1', 'Style', 'VsSlider', ...
    'Label', 'TX Focal X (mm)', ...
    'SliderMinMaxVal', [-xlim, xlim, 0], ... % X range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.0f'};
UI(1).Callback = @updateFocalPointX;

% Y-Axis Slider for TX Focal Point
UI(2).Control = {'UserB2', 'Style', 'VsSlider', ...
    'Label', 'TX Focal Y (mm)', ...
    'SliderMinMaxVal', [-ylim, ylim, 0], ... % Y range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.0f'};
UI(2).Callback = @updateFocalPointY;

% Z-Axis Slider for TX Focal Point
UI(3).Control = {'UserB3', 'Style', 'VsSlider', ...
    'Label', 'TX Focal Z (mm)', ...
    'SliderMinMaxVal', [0, zlim, 50], ... % Z range: 20mm to 100mm, default 50
    'SliderStep', [0.01, 0.1], ...
    'ValueFormat', '%3.0f'};
UI(3).Callback = @updateFocalPointZ;

% TrapType Slider for TX Control
UI(4).Control = {'UserB4', 'Style', 'VsSlider', ...
    'Label', 'Trap Type', ...
    'SliderMinMaxVal', [1, 6, 6], ... % TrapType range: 1 to 6, default 2 (focus)
    'SliderStep', [1/5, 1/5], ...
    'ValueFormat', '%1.0f'};
UI(4).Callback = @updateTrapType;

% Test Channel Slider
testChannel = 1;  % initial active element
UI(5).Control = {'UserB5','Style','VsSlider', ...
    'Label','Channel', ...
    'SliderMinMaxVal',[0, Resource.Parameters.numTransmit, testChannel], ...
    'SliderStep',[1/(Resource.Parameters.numTransmit-1), 10/(Resource.Parameters.numTransmit-1)], ...
    'ValueFormat','%3.0f'};
UI(5).Callback = @updateTestChannel;

%% Save all the structures to a .mat file.
name = 'TxTest';
save(['Verasonics-Acoustic-Tweezer/Data Files/',name,'.mat']);
disp(['Program name: ', name])
% save('C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\DIYMk1_MobileFocus_v2.mat');

%%

function TX = genTX(FocalPtMm,testChannel)

    Trans = evalin('base','Trans');

    TX = repmat(struct('waveform', 1, ...
                   'Origin', zeros(1,3), ...
                   'FocalPtMm', FocalPtMm, ...
                   'Apod', ones(1,Trans.numelements), ...
                   'Delay', zeros(1,Trans.numelements)),...
                   1,5); % matrix shape  

    for t = 1:5
        if testChannel > 0
            TX(t).Apod = zeros(1,Trans.numelements);
            TX(t).Apod(:,testChannel) = 1; % Activate only the testChannel element
        end
    end

    % TrapType is equivalent to TX index
    % Plane Wave
    TX(1).Delay = zeros(1,Trans.numelements);

    % Focus
    TX(2).Delay = computeTXDelays(TX(2));

    % Twin Trap
    twinPhase = (Trans.ElementPos(:,1)<0).*0.5;
    TX(3).Delay = computeTXDelays(TX(3)) + twinPhase';

    % RH Vortex
    RH_VortexDelay = compDelayVortex(Trans.ElementPos,1); % the last input is the topological charge
    TX(4).Delay = computeTXDelays(TX(4)) + RH_VortexDelay';

    % LH Vortex
%     LH_VortexDelay = flip(RH_VortexDelay);
    LH_VortexDelay = -(RH_VortexDelay);    
    TX(5).Delay = computeTXDelays(TX(5)) + LH_VortexDelay'+1;
end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command = 'triggerOut';

    SeqControl(2).command = 'timeToNextAcq';
    SeqControl(2).argument = TTNB; % us pause between pulses

    SeqControl(3).command = 'jump';
    SeqControl(3).argument = 1;
    SeqControl(3).condition = 'exitAfterJump';
end

function Event = genEvent(TrapType)
    TrapType = double(TrapType);

    if TrapType == 6
        Event(1).info = 'Balanced Vortex';
        Event(1).tx = 4; % RH Vortex
        Event(1).rcv = 0;
        Event(1).recon = 0; % no reconstruction.
        Event(1).process = 0; % no processing
        Event(1).seqControl = [1,2]; %

        Event(2).info = 'Balanced Vortex';
        Event(2).tx = 5; % LH Vortex
        Event(2).rcv = 0;
        Event(2).recon = 0; % no reconstruction.
        Event(2).process = 0; % no processing
        Event(2).seqControl = [1,2,3]; %
    else
        Event(1).info = 'Transmit';
        Event(1).tx = TrapType; % use TrapType TX structure.
        Event(1).rcv = 0;
        Event(1).recon = 0; % no reconstruction.
        Event(1).process = 0; % no processing
        Event(1).seqControl = [1,2];

        Event(2).info = 'Transmit';
        Event(2).tx = TrapType; % use TrapType TX structure.
        Event(2).rcv = 0;
        Event(2).recon = 0; % no reconstruction.
        Event(2).process = 0; % no processing
        Event(2).seqControl = [1,2,3];
    end

end

function updateFocalPointX(~, ~, UIValue)
    % Retrieve TX from the base workspace
    FocalPtMm = evalin('base', 'FocalPtMm');
    TrapType = evalin('base', 'TrapType');
    % Update only the X coordinate of the focal point
    FocalPtMm(1) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateTX(FocalPtMm,TrapType);
end

function updateFocalPointY(~, ~, UIValue)
    % Retrieve TX from the base workspace
    FocalPtMm = evalin('base', 'FocalPtMm');
    TrapType = evalin('base', 'TrapType');
    % Update only the Y coordinate of the focal point
    FocalPtMm(2) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateTX(FocalPtMm,TrapType);
end

function updateFocalPointZ(~, ~, UIValue)
    % Retrieve TX from the base workspace
    FocalPtMm = evalin('base', 'FocalPtMm');
    TrapType = evalin('base', 'TrapType');
    % Update only the Z coordinate of the focal point
    FocalPtMm(3) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateTX(FocalPtMm,TrapType);
end

function updateTrapType(~, ~, UIValue)
%     TrapType = evalin('base', 'TrapType');
    % Update the TrapType variable in the base workspace
    assignin('base', 'TrapType', int32(UIValue));
    FocalPtMm = evalin('base', 'FocalPtMm');
    % Update system
    updateTX(FocalPtMm,int32(UIValue));
end

function updateTestChannel(~, ~, UIValue)
    % Round and store selected test channel (0 = all elements)
    testChannel = round(UIValue);
    assignin('base','testChannel',testChannel);

    % Get current focal point and trap type
    FocalPtMm = evalin('base','FocalPtMm');
    TrapType  = evalin('base','TrapType');

    % Regenerate TX with (optional) single active element
    TX = genTX(FocalPtMm,testChannel);  % single element
    Event = genEvent(TrapType);

    % Push updates to base
    assignin('base','TX',TX);
    assignin('base','Event',Event);

    % Build Control updates (only need to push TX & Event)
    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'TX'};
    Control(2).Command = 'update&Run';
    Control(2).Parameters = {'Event'};
    assignin('base','Control',Control);

    % Console feedback
    if testChannel == 0
        disp('Test Channel: all elements active');
    else
        disp(['Test Channel active element: ', num2str(testChannel)]);
    end
end

function updateTX(FocalPtMm,TrapType)
testChannel = evalin('base','testChannel');
% **Recalculate TX Delays**
TX = genTX(FocalPtMm,testChannel);
Event = genEvent(TrapType);

% **Save updated TX back to base workspace**
assignin('base', 'TX', TX);
assignin('base','Event',Event)

% **Apply the updates with "update&Run"**
Control(1).Command = 'update&Run';
Control(1).Parameters = {'SeqControl'};

Control(2).Command = 'update&Run';
Control(2).Parameters = {'TX'};

Control(3).Command = 'update&Run';
Control(3).Parameters = {'Event'};

assignin('base', 'Control', Control);

% Print updated focal point for debugging
disp(['Current Focal Point: ', num2str(TX(1).FocalPtMm)]);
% Display the current Trap Type for debugging
trapTypeName = {'Plane', 'Focus', 'Twin', 'RH Vortex', 'LH Vortex', 'Switching Vortex'};
currentTrapType = evalin('base', 'TrapType');
% disp(currentTrapType)
disp(['Current Trap Type: ', trapTypeName{currentTrapType}]);
end

