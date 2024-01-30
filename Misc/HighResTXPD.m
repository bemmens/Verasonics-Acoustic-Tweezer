% -------------- High Res TXPD ----------------

clear all

% Specify system parameters
Resource.Parameters.numTransmit = 32; % no. of transmit channels

Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
%Resouce.Parameters.verbose = 2;
%Resource.Parameters.fakescanhead = 1;

% Specify Trans structure array.
load Trans_Ring

lambda_mm = Resouce.Parameters.speedOfSound*1e3/(Trans.frequency*1e6); %wavelength in mm

Trans.ElementPos(:,5) = zeros(32,1);

%----- spec focal dist in mm ------
%focalDist_mm = 40;
%focalDist_nW = focalDist_mm/lambda_mm;
PDepth_mm = 60;
PDepth_nW = PDepth_mm/lambda_mm;
%PDepth_nW = focalDist_nW*2;

probeDiameter = 70/lambda_mm;
dishDiameter = 39/lambda_mm;
bigDishDiameter = 90/lambda_mm;

% Specify PData structure array.
PData.PDelta = [0.05,0.05,0.5]; % x, y and z wavelengths per pixel
%PData.Size(1) = ceil(1.25*Trans.diameter/PData.PDelta(1));
PData.Size(1) = ceil(PDepth_nW/PData.PDelta(1));
PData.Size(2) = PData.Size(1);
PData.Size(3) = ceil(PDepth_nW/PData.PDelta(3)); 
%PData.Size(3) = 1; 
% PData.Origin is the location [x,y,z] of the upper lft corner of the array.
PData.Origin = [-PData.Size(1)*PData.PDelta(1)/2,PData.Size(2)*PData.PDelta(2)/2,0];

PDwidth_mm = PData.Size(1)*PData.PDelta(1)*lambda_mm
PDdepth_mm = PData.Size(3)*PData.PDelta(3)*lambda_mm


%TPC Settings
%TPC(5).maxHighVoltage = 80;
TPC(5).highVoltageLimit = 50;

% Specify Transmit waveform structure. 
pulseLength = 20; % ms
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,10,1]; % A, B, C, D
TW(1).equalize = 0;

% Specify TX structure array. 
fixedFocus = 0;
%fixedFocus = focalDist_nW;

% Left/Right Steering
thetas = linspace(-pi/32,pi/32,100);
na = length(thetas);

TX = repmat(struct('waveform', 1, ...
                   'Origin', zeros(1,3), ...
                   'focus', 0, ... % wavlengths
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,Trans.numelements), ...
                   'Delay', zeros(1,Trans.numelements)),1,1);
           
              
[RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
LH_VortexDelay = flip(RH_VortexDelay);
%DelayVector = zeros(Trans.numelements,1);

%TX.Delay = computeTXDelays(TX(1)) + RH_VortexDelay'; 
%TX(1).Delay = zeros(1,32);

theta_idx = na/2;

TX(1).waveform = 1;
TX(1).focus = fixedFocus;
TX(1).Steer = [thetas(theta_idx),0];
TX(1).Origin = [0,0,0];
TX(1).Apod = ones(1,Trans.numelements);
TX(1).Delay = computeTXDelays(TX(1)) + RH_VortexDelay'; 
TX(1).TXPD = computeTXPD(TX(1), PData);

TxSlider = 1;

% Sequence Controls
SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 5;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'noop';
SeqControl(2).argument = 50000 ;% 10 ms

SeqControl(3).command = 'timeToNextEB';
SeqControl(3).argument = 360; % us pause between pulses (10 is minimum specifiable)

SeqControl(4).command = 'returnToMatlab';

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 2;

SeqControl(6).command = 'setTPCProfile';
SeqControl(6).argument = 1;
SeqControl(6).condition = 'immediate';

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
nTransmitsPerCallback = ceil(usPerCallback/SeqControl(3).argument/2);
for i = 1:nTransmitsPerCallback
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = 3; 
    n = n+1;
    
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = 3; 
    n = n+1;
end

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
n = n+1;

% Create UI Controls
import vsv.seq.uicontrol.VsSliderControl
UI(1).Control = VsSliderControl('LocationCode','UserA1',...
                 'Label','Steering Angle',...
                 'SliderMinMaxVal',[1,length(thetas),round(length(thetas)/2)],... % min,max,initial
                 'SliderStep', [1/length(thetas),2/length(thetas)]);   % steps as a fraction of 1, 0->min, 1->max
UI(1).Callback = @defSteering;


% Save all the structures to a .mat file.
save('Barney/misc/Vortex_Ring_TXPD_HighRes'); 
disp('KerCHOW!')
%EventAnalysisTool
%VSX

function defSteering(~,~,UIValue)
assignin('base',"TxSlider",UIValue) % Variable correctly assigned but not affecting true steering angle (TX might need to be predefined).
end

