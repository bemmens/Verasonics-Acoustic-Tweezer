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
TPC(1).maxHighVoltage = 5; % Set max voltage to 30V


%% Specify TX structure array. 
TX.waveform = 1; % use 1st TW structure.
%TX.focus = 10; % distance (in wavelengths) from the Origin point on the transducer to where the beam comes to a focus
%TX.Steer = [0,0]; 
TX.FocalPtMm = [0,0,67]; %[1x3 double] FocalPt in mm instead of wavelengths
TX.Origin = [0,0,0];
TX.Apod = ones(1,Trans.numelements);
TX.Delay = computeTXDelays(TX); 

%% Specify sequence events.
Event(1).info = 'Start Trigger'; 
Event(1).tx = 1; % use 1st TX structure.
Event(1).rcv = 0; 
Event(1).recon = 0; % no reconstruction.
Event(1).process = 0; % no processing
Event(1).seqControl = [1,2]; % transfer data to host
 SeqControl(1).command = 'triggerOut';
 SeqControl(2).command = 'noop';
 SeqControl(2).argument = 16; % us pause between sequences

Npulses = 10000;
for n = 1:2+Npulses
    Event(n).info = 'TX'; 
    Event(n).tx = 1; % use 1st TX structure.
    Event(n).rcv = 0; 
    Event(n).recon = 0; % no reconstruction.
    Event(n).process = 0; % no processing
    Event(n).seqControl = [1,3]; % 
        SeqControl(3).command = 'timeToNextAcq';
        SeqControl(3).argument = 16; % us pause between pulses
end

Event(n+1).info = 'Check MatLab'; 
Event(n+1).tx = 0; % use 1st TX structure.
Event(n+1).rcv = 0; 
Event(n+1).recon = 0; % no reconstruction.
Event(n+1).process = 0; % no processing
Event(n+1).seqControl = [1,4]; % transfer data to host
    SeqControl(4).command = 'jump'; 
    SeqControl(4).argument = 1;
    SeqControl(4).condition = 'exitAfterJump';

 %% UI Control

 xlim = 100;
 ylim = xlim;
 zlim = 100;

% X-Axis Slider for TX Focal Point
UI(1).Control = {'UserB1', 'Style', 'VsSlider', ...
                 'Label', 'TX Focal X (mm)', ...
                 'SliderMinMaxVal', [-xlim, xlim, 0], ... % X range: -20mm to 20mm, default 0
                 'SliderStep', [1, 5], ...
                 'ValueFormat', '%3.0f'};
UI(1).Callback = @updateFocalPointX;

% Y-Axis Slider for TX Focal Point
UI(2).Control = {'UserB2', 'Style', 'VsSlider', ...
                 'Label', 'TX Focal Y (mm)', ...
                 'SliderMinMaxVal', [-ylim, ylim, 0], ... % Y range: -20mm to 20mm, default 0
                 'SliderStep', [1, 5], ...
                 'ValueFormat', '%3.0f'};
UI(2).Callback = @updateFocalPointY;

% Z-Axis Slider for TX Focal Point
UI(3).Control = {'UserB3', 'Style', 'VsSlider', ...
                 'Label', 'TX Focal Z (mm)', ...
                 'SliderMinMaxVal', [0, zlim, 67], ... % Z range: 20mm to 100mm, default 67
                 'SliderStep', [1, 5], ...
                 'ValueFormat', '%3.0f'};
UI(3).Callback = @updateFocalPointZ;



%% Save all the structures to a .mat file.
save('Verasonics-Tatsuki\Sequences\DIYMk1_MobileFocus.mat'); 
%save('C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\DIYMk1Test.mat'); 

%% 
function updateFocalPointX(~, ~, UIValue)
    % Retrieve TX from the base workspace
    TX = evalin('base', 'TX');
    
    % Update only the X coordinate of the focal point
    TX(1).FocalPtMm(1) = UIValue;
    
    % Update system
    updateTX(TX);
end

function updateFocalPointY(~, ~, UIValue)
    % Retrieve TX from the base workspace
    TX = evalin('base', 'TX');
    
    % Update only the Y coordinate of the focal point
    TX(1).FocalPtMm(2) = UIValue;
    
    % Update system
    updateTX(TX);
end

function updateFocalPointZ(~, ~, UIValue)
    % Retrieve TX from the base workspace
    TX = evalin('base', 'TX');
    
    % Update only the Z coordinate of the focal point
    TX(1).FocalPtMm(3) = UIValue;
    
    % Update system
    updateTX(TX);
end

function updateTX(TX)
    % **Recalculate TX Delays**
    TX.Delay = computeTXDelays(TX);

    % **Save updated TX back to base workspace**
    assignin('base', 'TX', TX);

    % **Ensure "Control" Exists Before Assigning**
    if evalin('base', 'exist(''Control'', ''var'')') == 0
        Control = struct([]);
    else
        Control = evalin('base', 'Control');
    end

    % **Apply the updates with "update&Run"**
    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'SeqControl'};

    Control(2).Command = 'update&Run';
    Control(2).Parameters = {'TX'};

    Control(3).Command = 'update&Run';
    Control(3).Parameters = {'Event'};

    assignin('base', 'Control', Control);

    % Print updated focal point for debugging
    disp(['Updated TX Focal Point: ', num2str(TX(1).FocalPtMm)]);
end

