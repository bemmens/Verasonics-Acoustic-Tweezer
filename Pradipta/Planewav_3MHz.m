% =========================================================================
%  3MHz_Planewave.m
%  Verasonics Vantage - uniform PLANE-WAVE transmit on a circular subaperture
%
%  Field:  a flat wavefront (zero relative delay) launched from a circular,
%          uniform-illumination subaperture of radius ApodRadius on the
%          10.8 x 10.8 mm, 11x11 array. Optional steering tilts the plane wave.
%
%  This is the plane-wave companion to 3MHz_IdealBesselVortex.m: same array and
%  same circular apodization, but with NO axicon / NO helical phase. Use it to
%  drive a clean plane wave into a passive 3D-printed vortex phase plate
%  (vortex_plate_final.py), which then imprints the Bessel-vortex phase.
%
%  CONTROLS (UserB1..B4)
%    B1  Steer X (deg)    - tilt the plane wave about the y-axis (0 = broadside)
%    B2  Steer Y (deg)    - tilt the plane wave about the x-axis (0 = broadside)
%    B3  Aperture R (mm)  - circular support radius; elements outside are OFF
%    B4  DriveScale       - effective amplitude 0..1 (SUB-1.6V operation)
%
%  DriveScale:  amplitude knob below the HV-rail floor. The TPC regulator
%  cannot hold below ~1.6 V, so to run "quieter" than that, keep the rail at
%  a clean few volts and scale TX.Apod by DriveScale. NOTE force ~ amplitude^2,
%  so DriveScale = 0.3 -> ~0.09x trapping force.
%
%  ANTI-ALIASING: pitch ~ 1 mm ~ 2*lambda. Steering phase step per element =
%  2*pi*(p/lambda)*sin(theta) must stay < pi  ->  |theta| < ~14.6 deg.
% =========================================================================

clear all

%% Resource
Resource.Parameters.numTransmit   = 121;
Resource.Parameters.connector     = 1;
Resource.Parameters.speedOfSound  = 1481;   % m/s (water)
Resource.Parameters.simulateMode  = 1;
Resource.System.UTA = '160-SH';

%% Trans
load 3MHz2D_Trans.mat   % 11x11, 10.8 x 10.8 mm, custom 2D array

%% Physical parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % m
lambda_mm  = wavelength*1e3;                                          % mm

%% -------- Plane-wave design parameters (read by genTX) ------------------
Steer      = [0 0];        % plane-wave steering (theta_x, theta_y) [deg], 0 = broadside
ApodRadius = 5.4;          % circular support radius [mm] -> elements OFF for r > R
ApodTaper  = 1.0;         % uniform-core fraction (soft raised-cosine edge)
DriveScale = 1.0;          % effective amplitude 0..1 (sub-1.6V knob)

steerStep = 360*(1.0/lambda_mm)*sin(max(abs(Steer))*pi/180);
fprintf('Plane wave: aperture R = %.2f mm, steer = [%.0f %.0f] deg\n', ...
        ApodRadius, Steer(1), Steer(2));
fprintf('Steering phase step per element: %.0f deg (keep < 180)\n', steerStep);

%% TW (quasi-CW burst)
nHalfCycles = 30;
TW(1).type       = 'parametric';
TW(1).Parameters = [Trans.frequency,1,nHalfCycles,1];
TW(1).equalize   = 0;

%% TPC (HV rail ceiling)
TPC(1).maxHighVoltage = 20;
TPC(1).highVoltageLimit = 20;


%% TX
TX = genTX();

%% Sequence
TTNB = 20;   % us
period_s  = 1/(Trans.frequency*1e6);
dutyCycle = ((nHalfCycles/2)*period_s)/(TTNB*1e-6);
fprintf('Duty cycle: %.2f%%\n', dutyCycle*100);

SeqControl = genSeqControl(TTNB);
Event      = genEvent();

%% UI
lim = 14;    % steering cap (deg) to stay below the grating-lobe / aliasing limit

UI(1).Control = {'UserB1','Style','VsSlider','Label','Steer X (deg)', ...
    'SliderMinMaxVal',[-lim,lim,0],'SliderStep',[1/28,1/14],'ValueFormat','%2.0f'};
UI(1).Callback = @updateSteerX;

UI(2).Control = {'UserB2','Style','VsSlider','Label','Steer Y (deg)', ...
    'SliderMinMaxVal',[-lim,lim,0],'SliderStep',[1/28,1/14],'ValueFormat','%2.0f'};
UI(2).Callback = @updateSteerY;

UI(3).Control = {'UserB3','Style','VsSlider','Label','Aperture R (mm)', ...
    'SliderMinMaxVal',[1,5.4,5.4],'SliderStep',[0.1/4.4,0.5/4.4],'ValueFormat','%3.1f'};
UI(3).Callback = @updateApodRadius;

% Effective amplitude (sub-1.6V operation)
UI(4).Control = {'UserB4','Style','VsSlider','Label','DriveScale', ...
    'SliderMinMaxVal',[0,1,1],'SliderStep',[0.01,0.05],'ValueFormat','%1.2f'};
UI(4).Callback = @updateDriveScale;

%% Save
name = '3MHz_Planewave';
save(['Verasonics-Acoustic-Tweezer\Data Files\',name,'.mat']);
disp(['Program name: ', name])

% =========================================================================
%                              FUNCTIONS
% =========================================================================

function TX = genTX()
    Trans  = evalin('base','Trans');
    steer  = evalin('base','Steer');
    Rap    = evalin('base','ApodRadius');
    tfrac  = evalin('base','ApodTaper');
    ds     = evalin('base','DriveScale');
    lam_mm = evalin('base','lambda_mm');
    N      = Trans.numelements;

    % element (x,y) in mm (handle wavelength/mm units)
    if isfield(Trans,'units') && strcmp(Trans.units,'wavelengths')
        pos = Trans.ElementPos(:,1:2)*lam_mm;
    else
        pos = Trans.ElementPos(:,1:2);
    end

    % circular uniform apodization (raised-cosine soft edge); OFF outside Rap
    rabs = hypot(pos(:,1),pos(:,2));
    w = ones(N,1);
    w(rabs > Rap) = 0;
    r0 = tfrac*Rap;
    edge = (rabs > r0) & (rabs <= Rap);
    w(edge) = 0.5*(1 + cos(pi*(rabs(edge)-r0)/(Rap-r0)));

    % single plane-wave TX; DriveScale sets effective amplitude
    TX = struct('waveform',1, ...
                'Origin',zeros(1,3), ...
                'FocalPtMm',[0 0 0], ...       % inert (delays computed directly)
                'Apod',(ds*w)', ...
                'Delay',zeros(1,N));
    TX.Delay = planeWaveDelay(pos, steer, lam_mm, w);
end

function D = planeWaveDelay(pos, steer, lam_mm, w)
    % flat wavefront (broadside) with optional linear steering, in wavelengths.
    % steer = [theta_x theta_y] in degrees; [0 0] -> all delays zero (plane wave).
    tx = steer(1)*pi/180;
    ty = steer(2)*pi/180;
    D  = (pos(:,1)*sin(tx) + pos(:,2)*sin(ty))/lam_mm;   % wavelengths

    act = w > 0;
    if any(act)
        D = D - min(D(act));                 % non-negative over active set
    end
    D(~act) = 0;
    D = D';
end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command  = 'triggerOut';
    SeqControl(2).command  = 'timeToNextAcq';
    SeqControl(2).argument = TTNB;
    SeqControl(3).command   = 'jump';
    SeqControl(3).argument  = 1;
    SeqControl(3).condition = 'exitAfterJump';
end

function Event = genEvent()
    Event(1).info      = 'Plane wave';
    Event(1).tx        = 1;
    Event(1).rcv       = 0;
    Event(1).recon     = 0;
    Event(1).process   = 0;
    Event(1).seqControl = [1,2];

    Event(2).info      = 'Plane wave';
    Event(2).tx        = 1;
    Event(2).rcv       = 0;
    Event(2).recon     = 0;
    Event(2).process   = 0;
    Event(2).seqControl = [1,2,3];
end

function updateSteerX(~, ~, UIValue)
    steer = evalin('base','Steer'); steer(1) = UIValue;
    assignin('base','Steer',steer); updateTX();
end

function updateSteerY(~, ~, UIValue)
    steer = evalin('base','Steer'); steer(2) = UIValue;
    assignin('base','Steer',steer); updateTX();
end

function updateApodRadius(~, ~, UIValue)
    assignin('base','ApodRadius',max(0.5,UIValue)); updateTX();
end

function updateDriveScale(~, ~, UIValue)
    assignin('base','DriveScale',max(0,min(1,UIValue))); updateTX();
end

function updateTX()
    TX = genTX();
    assignin('base','TX',TX);

    Control(1).Command    = 'update&Run';
    Control(1).Parameters = {'TX'};
    assignin('base','Control',Control);

    steer = evalin('base','Steer');
    Rap   = evalin('base','ApodRadius');
    ds    = evalin('base','DriveScale');

    % Read the current HV rail from the TPC struct (fall back gracefully)
    hv = NaN;
    if evalin('base','exist(''TPC'',''var'')')
        TPC = evalin('base','TPC');
        if isfield(TPC,'hv') && ~isempty(TPC(1).hv)
            hv = TPC(1).hv;                 % runtime rail voltage [V]
        elseif isfield(TPC,'maxHighVoltage')
            hv = TPC(1).maxHighVoltage;     % ceiling, if runtime hv not set yet
        end
    end
    Veff = ds*hv;                            % effective drive amplitude [V-equiv]

    disp(['Steer (x,y) deg: ', num2str(steer), ...
          ' | Aperture R = ', num2str(Rap,'%.1f'), ' mm', ...
          ' | DriveScale = ', num2str(ds,'%.2f'), ...
          ' | HV rail = ', num2str(hv,'%.2f'), ' V', ...
          ' | V_eff = ', num2str(Veff,'%.2f'), ' V-equiv', ...
          ' (force ~ ', num2str(ds^2,'%.3f'), 'x at this rail)']);
end
