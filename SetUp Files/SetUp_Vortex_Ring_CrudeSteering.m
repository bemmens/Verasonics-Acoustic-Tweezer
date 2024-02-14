clear all

% Specify system parameters
Resource.Parameters.numTransmit = 32; % no. of transmit channels
Resource.Parameters.connector = [1]; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
%Resouce.Parameters.verbose = 2;
%Resource.Parameters.fakescanhead = 1;

% Specify Trans structure array.
load Trans_Ring

lambda_mm = Resouce.Parameters.speedOfSound*1e3/(Trans.frequency*1e6);

Trans.ElementPos(:,5) = zeros(32,1);

%spec focal dist in mm
%focalDist_mm = 22;
%focalDist_nW = focalDist_mm*mmToNW;
PDepth_mm = 30;
PDepth_nW = PDepth_mm/lambda_mm;

probeDiameter = 70/lambda_mm;
dishDiameter = 39/lambda_mm;
bigDishDIAm = 90/lambda_mm;

% Specify PData structure array.
PData.PDelta = [0.1,0.1,0.5]; % x, y and z wavelengths per pixel
%PData.Size(1) = ceil(1.25*Trans.diameter/PData.PDelta(1));
PData.Size(1) = ceil(bigDishDIAm/PData.PDelta(1));
PData.Size(2) = PData.Size(1);
PData.Size(3) = ceil(PDepth_nW/PData.PDelta(3)); 
PData.Size(3) = 1; 
% PData.Origin is the location [x,y,z] of the upper lft corner of the array.
PData.Origin = [-PData.Size(1)*PData.PDelta(1)/2,PData.Size(2)*PData.PDelta(2)/2,PDepth_nW];

%TPC Settings
%TPC(5).maxHighVoltage = 80;
TPC(5).highVoltageLimit = 50;

% Specify Transmit waveform structure. 
%pulseLength = 20; % ms
%nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,0.9,100,1]; % A, B, C, D
TW(1).equalize = 0;


% Specify TX structure array. 
fixedFocus = 0;

% Left/Right Steering
thetas = linspace(0,pi/3,200);
na = length(thetas);

TX = repmat(struct('waveform', 1, ...
                   'Origin', zeros(1,3), ...
                   'focus', 0, ...
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,Trans.numelements), ...
                   'Delay', zeros(1,Trans.numelements)),1,2*na);
           
              
[RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
LH_VortexDelay = flip(RH_VortexDelay);
%DelayVector = zeros(Trans.numelements,1);

%TX.Delay = computeTXDelays(TX(1)) + RH_VortexDelay'; 
%TX(1).Delay = zeros(1,32);


for j = 1:na
    TX(j).waveform = 1;
    TX(j).focus = fixedFocus;
    TX(j).Steer = [thetas(j),0];
    TX(j).Origin = [0,0,0];
    TX(j).Apod = ones(1,Trans.numelements);
    TX(j).Delay = computeTXDelays(TX(j)) + RH_VortexDelay'; 
    %TX(j).TXPD = computeTXPD(TX(j), PData);
end

for j = na+1:(2*na)
    TX(j).waveform = 1;
    TX(j).focus = fixedFocus;
    TX(j).Steer = [thetas(j-na),0];
    TX(j).Origin = [0,0,0];
    TX(j).Apod = ones(1,Trans.numelements);
    TX(j).Delay = computeTXDelays(TX(j)) + LH_VortexDelay'; 
    %TX(j).TXPD = computeTXPD(TX(j), PData);
end


%TxSlider = length(thetas)/2;
TxSlider = 1;


% Sequence Controls
SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 5;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'noop';
SeqControl(2).argument = 50000 ;% 10 ms

SeqControl(3).command = 'timeToNextAcq';
SeqControl(3).argument = 360; % us pause between pulses (10 is minimum specifiable)

SeqControl(4).command = 'returnToMatlab';

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 4;

SeqControl(6).command = 'setTPCProfile';
SeqControl(6).argument = 1;
SeqControl(6).condition = 'immediate';

SeqControl(7).command = 'triggerOut';

% Specify Event structure arrays.
n = 1;

% Push % For any script using multiple TPC profiles, and especially any
% script using Profile 5 for Push transmit, the script must explicitly
% specify an initial profile at the beginning of the script, prior to any
% transmit events.  This is to prevent the script from 'inheriting'
% whatever TPC Profile was in effect when some previous script was
% terminated.
Event(n).info = 'select TPC profile';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 6;
n = n+1;

% Specify sequence events.
Event(n).info = 'Charge Capacitor'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [2]; 
n = n+1;

Event(n).info = 'Engage Extended Transmit'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [1]; 
n = n+1;

usPerCallback = 10000;
nTransmitsPerCallback = ceil(usPerCallback/SeqControl(3).argument/2); % nTransmitsPerCallback only counts on handedness so nTX will be twice as high
n_TX0 = n;
for i = 1:nTransmitsPerCallback
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = [3,7]; 
    n = n+1;
    
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider+na; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = [3,7]; 
    n = n+1;
end
n_TXEnd = n;

%{
% Sweep for testing
for j = 1:length(thetas)
Event(n).info = 'Transmit'; 
Event(n).tx = j+1; 
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 3; 
n = n+1;
end
%}

Event(n).info = 'Check for GUI update'; 
Event(n).tx = 0; 
Event(n).rcv = 0; 
Event(n).recon = 0; % no reconstruction.
Event(n).process = 0; % no processing
Event(n).seqControl = [4,5]; 

% Create UI Controls
import vsv.seq.uicontrol.VsSliderControl
UI(1).Control = VsSliderControl('LocationCode','UserA1',...
                 'Label','Steering Angle',...
                 'SliderMinMaxVal',[1,length(thetas),round(length(thetas)/2)],... % min,max,initial
                 'SliderStep', [1/length(thetas),2/length(thetas)]);   % steps as a fraction of 1, 0->min, 1->max
UI(1).Callback = @defSteering;

% Save all the structures to a .mat file.
save('Barney/BarneyArchive/Barney_14Dec23/Barney/data_files/Vortex_Ring_Steerable'); 
disp('KerCHOW!')
EventAnalysisTool
%VSX

function defSteering(~,~,UIValue)
    TxSlider = round(UIValue);
    assignin('base',"TxSlider",TxSlider) 

    n_TX0 = evalin("base",'n_TX0');
    na = evalin("base",'na');
    Event = evalin("base",'Event');
    nTransmitsPerCallback = evalin("base",'nTransmitsPerCallback');
    %n_TXEnd = evalin("base",'n_TXEnd');
    n = n_TX0;
    for i = n_TX0:nTransmitsPerCallback+n_TX0
        Event(n).info = 'Transmit'; 
        Event(n).tx = TxSlider; 
        Event(n).rcv = 0; 
        Event(n).recon = 0; 
        Event(n).process = 0; 
        Event(n).seqControl = [3,7]; 
        n = n+1;
        
        Event(n).info = 'Transmit'; 
        Event(n).tx = TxSlider+na; 
        Event(n).rcv = 0; 
        Event(n).recon = 0; 
        Event(n).process = 0; 
        Event(n).seqControl = [3,7]; 
        n = n+1;
    end

    Event(n).info = 'Check for GUI update'; 
    Event(n).tx = 0; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; % no reconstruction.
    Event(n).process = 0; % no processing
    Event(n).seqControl = [4,5]; 

    assignin('base', 'Event',Event);

    Control = evalin('base', 'Control');
    Control.Command = 'update&Run';
    %Control.Parameters = {'Event',n_TX0,'tx',round(UIValue)};
    Control.Parameters = {'Event'};
    assignin('base', 'Control',Control);
end

