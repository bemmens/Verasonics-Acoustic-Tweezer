clear all

%% Generate Resource
Resource.Parameters.numTransmit = 32; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resouce.Parameters.speedOfSound = 1481;

%% Generate Trans
load Trans_Ring

%% NO Physical Parameters

%% NO TPC5
%% TPC Settings
TPC(1).maxHighVoltage = 20;

%% Generate TW
pulseLength = 20; % ms
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,0.9,100,1]; % A, B, C, D
TW(1).equalize = 0;

%% Default TX

TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,1); % matrix shape  

[RH_VortexDelay,~] = compDelayVortex(Trans.ElementPos,0);
TX(1).Delay = RH_VortexDelay'; 

%% Generate Sequence Controls

SeqControl(1).command = 'timeToNextAcq';
SeqControl(1).argument = 360; % us pause between pulses (10 is minimum specifiable)

SeqControl(2).command = 'jump'; 
SeqControl(2).argument = 1;
SeqControl(2).condition = 'exitAfterJump';

SeqControl(3).command = 'jump'; 
SeqControl(3).condition = 'exitAfterJump';

%% Default Event Sequence

Event = repmat(struct('info','Defalt Stationary', ...
                       'tx',1, ...
                       'rcv',0, ...
                       'recon',0, ...
                       'process',0, ...
                       'seqControl',1), ...
                       1,10);

Event(1).info = 'First Defalt Transmit'; 
Event(end).info = 'Last Default Transmit';
Event(end).seqControl = [1,2]; 

%% Create UI Controls
sliderGranularity = 100;
import vsv.seq.uicontrol.VsSliderControl
UI(1).Control = VsSliderControl('LocationCode','UserA1',...
                 'Label','Vortex Loc (mm)',... 
                 'SliderMinMaxVal',[-10,10,0],... % min,max,default in mm
                 'SliderStep', [1/sliderGranularity,5/sliderGranularity]);   
UI(1).Callback = @defMove;

%% Save To .mat File
savedir = 'C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\';
% Save all the structures to a .mat file.
save(strcat(savedir,'SM_Break')); 

function defMove(~,~,UIValue)
disp(UIValue)

% 'Change' TX Struct - Different TX parameters and N TX
Trans = evalin('base','Trans');
TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2); % matrix shape  

[RH_VortexDelay,~] = compDelayVortex(Trans.ElementPos,0);
LH_VortexDelay = flip(RH_VortexDelay);
TX(1).Delay = LH_VortexDelay'; 
TX(2).Delay = RH_VortexDelay';
assignin('base',"TX",TX)

% Change Event Struct - Length and event titles and TX selection
Event = repmat(struct('info','GUI Test', ...
                       'tx',1, ...
                       'rcv',0, ...
                       'recon',0, ...
                       'process',0, ...
                       'seqControl',1), ...
                       1,5);

Event(1).info = 'First GUI Test'; 
Event(end).info = 'Last GUI Test';
Event(end).seqControl = [1,2]; 

Event(1).tx = 2; % This line caused the bug!

assignin('base',"Event",Event)

% Control update&Run
Control = evalin('base', 'Control');
Control(1).Command = 'update&Run';
Control(1).Parameters = {'TX'};

Control(2).Command = 'update&Run';
Control(2).Parameters = {'Event'};
assignin('base', 'Control',Control);
end




























