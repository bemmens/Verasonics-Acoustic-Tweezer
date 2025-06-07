clear all

%% Generate Resource
Resource.Parameters.numTransmit = 121; % no. of transmit channels % CHECK
Resource.Parameters.connector = 1; % trans. connector to use (V 256). % CHECK
Resouce.Parameters.speedOfSound = 1481; % CHECK
Resource.Parameters.simulateMode = 1;

Resource.System.UTA = '160-SH';

%% Generate Trans
load DIYMk1Trans.mat % CHECK

%% Physical Parameters
wavelength = Resouce.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

H = 65*1e-3; %PD depth in m
H_wavelengths = H/wavelength; % PD depth in wavelengths CHECK

probeDiameter = 70e3/wavelength; % In wavelengths % CHECK
dishDiameter = 39e3/wavelength;
bigDishDIAm = 90e3/wavelength;

%% TPC Settings
TPC(5).maxHighVoltage = 20; % CHECK

%% Generate TW
%pulseLength = 20; % ms
%nHalfCycles = int32(2*pulseLength*Trans.frequency);
TW(1).type = 'parametric'; 
TW(1).Parameters = [Trans.frequency,0.9,20,1]; % A, B, C, D % CHECK
TW(1).equalize = 0;

%% Specify Default TX structure array. 
rmin = -30; % max steering range in mm % CHECK
rmax = 30; % CHECK
defaultLoc = 0; % default tweezer position in mm % CHECK
currentLoc = defaultLoc;

[DefaultTX,~,naDefault] = genMoveTX(defaultLoc,defaultLoc); % no movement
TX = DefaultTX;
%% Generate Sequence Controls
SeqControl = genSeqControls;

%% Generate Default Event Sequence
[InitialiseEvent,n1] = genInitialiseEvent();
[DefaultEvent,n2] = genDefaultEvent(naDefault);
Event = [InitialiseEvent,DefaultEvent];

%% Create UI Controls
sliderGranularity = 100;
import vsv.seq.uicontrol.VsSliderControl
UI(1).Control = VsSliderControl('LocationCode','UserA1',...
                 'Label','Vortex Loc (mm)',... 
                 'SliderMinMaxVal',[rmin,rmax,defaultLoc],... % min,max,default in mm
                 'SliderStep', [1/sliderGranularity,5/sliderGranularity]);   
UI(1).Callback = @defMove;

%% Save To .mat File
%savedir = 'C:\Users\gv19838\OneDrive - University of Bristol\PhD\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\';
savedir = "C:\Users\verasonics\Documents\Vantage-4.8.4-2305101400\Verasonics-Acoustic-Tweezer\Data Files\";
% Save all the structures to a .mat file.
save(strcat(savedir,'SmoothMove'));  % CHECK

%% Functions
function [TX,rs,naMove] = genMoveTX(currentLoc,nextLoc)
    % currentLoc and nextLoc in mm

    %Specify largest steering step
    wavelength = evalin('base','wavelength');
    dr = wavelength/100;
    if dr>wavelength/2
        disp('ERROR:dr too large!')
        DISP('-------------------')
    end
    
    H = evalin('base','H'); % m
    r0 = currentLoc; %mm
    rTarget = nextLoc; % mm

    if rTarget - r0 < 0
        dr = -dr;
    end
    
    distance = (rTarget - r0)/1e3 ;% now to m
    nLargestSteps = floor(distance/dr);
    N = nLargestSteps+1;
    
    %Specify list of positions to move through
        % Includes r0 position (could be removed if move needs to be faster).
    rs = dr*(0:N) + (r0/1000);
    rs(N+1) = rTarget/1000;% x coords of 1st to last position
    thetasMove = pi/2 - cart2pol(rs,H);
    
    naMove = length(thetasMove);
    Trans = evalin('base','Trans');
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 65*1e-3/wavelength, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2*naMove); % matrix shape  
    
    [RH_VortexDelay,~] = compDelayVortex(Trans.ElementPos,0);
    LH_VortexDelay = flip(flip(RH_VortexDelay));
    
    for j = 1:naMove
        TX(j).Steer = [thetasMove(j),0];
        TX(j).Delay = RH_VortexDelay' + computeTXDelays(TX(j)); 
    end
    for j = naMove+1:(2*naMove)
        TX(j).Steer = [thetasMove(j-naMove),0];
        TX(j).Delay = LH_VortexDelay' + computeTXDelays(TX(j)); 
    end
    
end

function SeqControl = genSeqControls

SeqControl(1).command = 'setTPCProfile';
SeqControl(1).argument = 1;
SeqControl(1).condition = 'immediate';

SeqControl(2).command = 'setTPCProfile';
SeqControl(2).argument = 5;
SeqControl(2).condition = 'immediate';

SeqControl(3).command = 'noop';
SeqControl(3).argument = 10 ;% us REDUNDANT??

SeqControl(4).command = 'timeToNextEB';
SeqControl(4).argument = 10; % us pause between pulses (10 is minimum specifiable)

SeqControl(5).command = 'jump'; 
SeqControl(5).argument = 1;
SeqControl(5).condition = 'exitAfterJump';

SeqControl(6).command = 'jump'; 
SeqControl(6).argument = 4; % Default
SeqControl(6).condition = 'exitAfterJump';

SeqControl(7).command = 'triggerOut';
end

function [Event,n] = genInitialiseEvent()
n=1;
Event(n).info = 'select TPC profile';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 1;
n = n+1;

Event(n).info = 'Charge Capacitor'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 2; 
n = n+1;

Event(n).info = 'Engage Extended Transmit'; 
Event(n).tx = 0;
Event(n).rcv = 0; 
Event(n).recon = 0; 
Event(n).process = 0; 
Event(n).seqControl = 3; 
end

function [Event,n] = genDefaultEvent(naDefault)

nTXperCallback = 2*10; % must be even

Event = repmat(struct('info','Defalt Stationary', ...
                       'tx',0, ...
                       'rcv',0, ...
                       'recon',0, ...
                       'process',0, ...
                       'seqControl',4), ...
                       1,nTXperCallback);

n=1;
for i = 1:(nTXperCallback/2)
    Event(n).tx = 1;
    n=n+1;
    Event(n).tx = 1+naDefault;
    n=n+1;
end
n = n-1;

Event(1).info = 'First Defalt Transmit'; 
Event(end).info = 'Last Default Transmit';
Event(end).seqControl = [4,5]; 

end

function defMove(~,~,UIValue)
nextLoc = UIValue;
assignin('base',"nextLoc",nextLoc)
currentLoc = evalin('base','currentLoc');

disp('----------')
disp('Moving to:')
disp(nextLoc)

% create new TX and Event
[TX,~,naMove] = genMoveTX(currentLoc,nextLoc);

assignin('base',"TX",TX)

[InitEvent,n1] = genInitialiseEvent();
[MoveEvent,n2] = genMoveEvent(naMove);

SeqControl = evalin('base','SeqControl');
SeqControl(6).argument = n1+n2;

assignin('base',"SeqControl",SeqControl)

[StationaryEvent,~] = genNewStationaryEvent(naMove);

Event = [InitEvent,MoveEvent,StationaryEvent];

assignin('base',"Event",Event)

% Control update&Run
Control = evalin('base', 'Control');

Control(1).Command = 'update&Run';
Control(1).Parameters = {'SeqControl'};

Control(2).Command = 'update&Run';
Control(2).Parameters = {'TX'};

Control(3).Command = 'update&Run';
Control(3).Parameters = {'Event'};

assignin('base', 'Control',Control);

disp('Done')

end

function [Event,n] = genMoveEvent(naMove)

Event = repmat(struct('info','Move', ...
                       'tx',0, ...
                       'rcv',0, ...
                       'recon',0, ...
                       'process',0, ...
                       'seqControl',4), ...
                       1,2*naMove);

rhTXidx = 1:naMove;
lhTXidx = naMove+1:(2*naMove);

n=1;
for i = 1:naMove
    Event(n).tx = rhTXidx(i);
    n=n+1;
    Event(n).tx = lhTXidx(i);
    n=n+1;
end

Event(end).seqControl = [4,6];

end

function [Event,n] = genNewStationaryEvent(naMove)

nTXperCallback = 2*10; % must be even

Event = repmat(struct('info','Stationary', ...
                       'tx',0, ...
                       'rcv',0, ...
                       'recon',0, ...
                       'process',0, ...
                       'seqControl',4), ...
                       1,nTXperCallback);

n=1;
for i = 1:(nTXperCallback/2)
    Event(n).tx = naMove;
    n=n+1;
    Event(n).tx = 2*naMove;
    n=n+1;
end
n = n-1;
Event(end).seqControl = [4,6]; 

end








