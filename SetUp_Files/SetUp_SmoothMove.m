clear all

%% Generate Resource
Resource.Parameters.numTransmit = 32; % no. of transmit channels

Resource.Parameters.connector = [1]; % trans. connector to use (V 256).
Resource.Parameters.simulateMode = 1; % runs script in simulate mode
Resouce.Parameters.speedOfSound = 1481;
%Resouce.Parameters.initializeOnly = 1;
%Resouce.Parameters.verbose = 2;
%Resource.Parameters.fakescanhead = 1;

%% Generate Trans
load Trans_Ring

lambda_mm = Resouce.Parameters.speedOfSound*1e3/(Trans.frequency*1e6);
wavelength = lambda_mm*1e-3;

Trans.ElementPos(:,5) = zeros(32,1);

%spec focal dist in mm
%focalDist_mm = 22;
%focalDist_nW = focalDist_mm*mmToNW;
PDepth_mm = 30;
H = PDepth_mm*1e-3; %PDepth in m
PDepth_nW = PDepth_mm/lambda_mm;

probeDiameter = 70/lambda_mm;
dishDiameter = 39/lambda_mm;
bigDishDIAm = 90/lambda_mm;

%% Generate PDaata
PData.PDelta = [0.1,0.1,0.5]; % x, y and z wavelengths per pixel
%PData.Size(1) = ceil(1.25*Trans.diameter/PData.PDelta(1));
PData.Size(1) = ceil(bigDishDIAm/PData.PDelta(1));
PData.Size(2) = PData.Size(1);
PData.Size(3) = ceil(PDepth_nW/PData.PDelta(3)); 
PData.Size(3) = 1; 
% PData.Origin is the location [x,y,z] of the upper lft corner of the array.
PData.Origin = [-PData.Size(1)*PData.PDelta(1)/2,PData.Size(2)*PData.PDelta(2)/2,PDepth_nW];

%% TPC Settings
TPC(5).maxHighVoltage = 20;
%TPC(5).highVoltageLimit = 20;

%% Generate TW
pulseLength = 20; % ms
nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,1,10,1]; % A, B, C, D
TW(1).equalize = 0;


%% Specify TX structure array. 
rmin = -30; % mm
rmax = 30;
N = 10; % Number of positions available
currentLoc = 10;
nextLoc = 11;
TXStationary = genTXSationary(rmin,rmax,N);
TXMove = genTXMove(currentLoc,nextLoc);
TX = [TXStationary,TXStationary];

%currentLoc = 0*1e-3; % current steering position in m
%nextLoc = 0; % next loc called for by slider

%% Generate Sequence Controls
SeqControl = genSeqControls;

%% Generate Initial Event Sequence
[EventInitial,n1] = genEventInitial();
[EventOldStationary,n2] = genEventOldStationary();
Event = [EventInitial,EventOldStationary];
%EventGUI



%[EventMove,n3] = genEventMove();
%[EventNewSationary,n4] = genEventNewStationary();
%Event = [EventInitial,EventOldStationary,EventMove,EventNewSationary];
%% Create UI Controls
import vsv.seq.uicontrol.VsSliderControl
UI(1).Control = VsSliderControl('LocationCode','UserA1',...
                 'Label','Vortex Loc (mm)',... 
                 'SliderMinMaxVal',[rmin,rmax,0],... % min,max,initial mm
                 'SliderStep', [1/(length(thetas)-1),2/(length(thetas)-1)]);   
UI(1).Callback = @defSteering;

%% Save all the structures to a .mat file.
savedir = 'C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\data_files\';
% Save all the structures to a .mat file.
save(strcat(savedir,'SmoothMove')); 

%% Callback timing
%{
Control.Command = 'update&Run';
Control.Parameters = {'Event'};
f = @() defSteering(1,1,rad2deg(thetas(1)));
eventUpdateTime = timeit(f)*1e6;
disp(['Event Update Time: ' num2str(eventUpdateTime) 'us'])
%}


%% Automatic VSX Execution:
% Uncomment the following line to automatically run VSX every time you run
% this SetUp script (note that if VSX finds the variable 'filename' in the
% Matlab workspace, it will load and run that file instead of prompting the
% user for the file to be used):

%disp('KerCHOW!')
%EventAnalysisTool
% filename = 'L11-5vIdealCBranch';  VSX;


%% Functions

function out = defSteering(~,~,nextLoc)

    currentLoc = evalin('base','currentLoc');
    %assignin('base',"nextLoc",nextLoc) ;
    


%{
    na = evalin("base",'na');
    %Event = evalin("base",'Event');
    Event = genEventSeq(na,TxIdx);
    assignin('base', 'Event',Event);

    Control = evalin('base', 'Control');
    Control.Command = 'update&Run';
    Control.Parameters = {'Event'};
    assignin('base', 'Control',Control);

    assignin('base',"currentLoc",nextLoc) ;
%}
    out = 1;
end

function [Event,n] = genEventInitial()
n=1;
Event(n).info = 'select TPC profile';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 6;
n = n+1;

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
end

function [Event,n] = genEventOldStationary(currentLoc)

TTNB = evalin('base','SeqControl(3).argument');


%n_TX0 = n;
%assignin('base',"n_TX0",n_TX0) 
Event(n).info = 'First Transmit'; 
Event(n).tx = TxSlider; 
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [7,3]; 
n = n+1;

Event(n).info = 'Transmit'; 
Event(n).tx = TxSlider+naStationary; 
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 3; 
n = n+1;

usPerCallback = 5000-(4*TTNB);
%nTransmitsPerCallback = 3;
nTransmitsPerCallback = ceil(usPerCallback/TTNB/2); % nTransmitsPerCallback only counts on handedness so nTX will be twice as high
assignin('base','nTransmitsPerCallback',nTransmitsPerCallback)
for i = 1:nTransmitsPerCallback
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = 3; 
    n = n+1;
    
    Event(n).info = 'Transmit'; 
    Event(n).tx = TxSlider+naStationary; 
    Event(n).rcv = 0; 
    Event(n).recon = 0; 
    Event(n).process = 0; 
    Event(n).seqControl = 3; 
    n = n+1;
end

Event(n).info = 'Transmit'; 
Event(n).tx = TxSlider; 
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 3; 
n = n+1;

Event(n).info = 'Last Transmit'; 
Event(n).tx = TxSlider+naStationary; 
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = [3,8]; % If bFlag~=0 jump to smoothMove Events
    SeqControl(8).command = 'cBranch';
    SeqControl(8).condition = bFlag;
    SeqControl(8).argument = moveEventIdx; 
%n_TXEnd = n;
n = n+1;
end

%{
Event(n).info = 'Check for GUI update'; 
Event(n).tx = 0; 
Event(n).rcv = 0; 
Event(n).recon = 0; % no reconstruction.
Event(n).process = 0; % no processing
Event(n).seqControl = [5]; 
%}

function SeqControl = genSeqControls
% Sequence Controls
SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 5;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'noop';
SeqControl(2).argument = 50000 ;% 5 ms

SeqControl(3).command = 'timeToNextEB';
SeqControl(3).argument = 360; % us pause between pulses (10 is minimum specifiable)

SeqControl(4).command = 'returnToMatlab';

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 4;
SeqControl(5).condition = 'exitAfterJump';

SeqControl(6).command = 'setTPCProfile';
SeqControl(6).argument = 1;
SeqControl(6).condition = 'immediate';

SeqControl(7).command = 'triggerOut';
end

function TX = genTXMove(currentLoc,nextLoc)
    
    %Specify largest steering step
    wavelength = evalin('base','wavelength');
    dr = wavelength/10;
    if dr>wavelength/2
        disp('ERROR:dr too large!')
        DISP('-------------------')
    end
    
    H = evalin('base','H'); % m
    r0 = currentLoc; %mm
    rTarget = nextLoc; % mm
    
    distance = (rTarget - r0)/1e3 ;%now to m
    nLargestSteps = floor(distance/dr);
    N = nLargestSteps+1;
    %drPrecisionStep = distance-(dr*nLargestSteps);
    %drTotal = nLargestSteps*dr + drPrecisionStep;
    
    %Specify list of positions to move through
        % Includes r0 position (could be removed if move needs to be faster).
    rs = dr*(0:N) + (r0/1000);
    rs(N+1) = rTarget/1000;% x coords of 1st to last position
    thetasMove = pi/2 - cart2pol(rs,H);
    
    naMove = length(thetasMove);
    Trans = evalin('base','Trans');
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2*naMove); % matrix shape  
    
    [RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
    LH_VortexDelay = flip(RH_VortexDelay);
    
    for j = 1:naMove
        TX(j).Steer = [thetasMove(j),0];
        TX(j).Delay = RH_VortexDelay'; 
    end
    for j = naMove+1:(2*naMove)
        TX(j).Steer = [thetasMove(j-naMove),0];
        TX(j).Delay = LH_VortexDelay'; 
    end
    
end

function TX = genTXSationary(rmin,rmax,N)
    % N number of possible positions should be odd to allow central
    % position
    %rmin = -30; % mm
    %rmax = 30;
    H = evalin('base','H'); % m
    rs = linspace(rmin,rmax,N)*1e-3;%radial loc in m
    thetas = pi/2 - cart2pol(rs,H); % steering angles in rad
    naStationary = length(thetas);
    Trans.numelements = evalin('base','Trans.numelements');
    Trans.ElementPos = evalin('base','Trans.ElementPos');
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2*naStationary); % matrix shape  
    [RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
    LH_VortexDelay = flip(RH_VortexDelay);
    for j = 1:naStationary
        TX(j).Steer = [thetas(j),0];
        TX(j).Delay = RH_VortexDelay'; 
    end
    for j = naStationary+1:(2*naStationary)
        TX(j).Steer = [thetas(j-naStationary),0];
        TX(j).Delay = LH_VortexDelay'; 
    end

end