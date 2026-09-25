% =========================================================================
%  3MHz_IdealBesselVortex.m
%  Verasonics Vantage - single ideal uniform Bessel vortex tweezer
%
%  Field:  p(r,phi,z) ~ J_ell(k_r r) e^{i ell phi} e^{i k_z z}
%          k_r = k sin(beta),  k_z = k cos(beta)
%  built from an AXICON (conical) delay law + helical phase, on a circular
%  uniform-illumination subaperture of the 10.8 x 10.8 mm, 11x11 array.
%
%  CONTROLS (UserB1..B5)
%    B1  Apex X (mm)      - translate the Bessel core laterally
%    B2  Apex Y (mm)      - translate the Bessel core laterally
%    B3  Axicon beta (deg)- ring size / axial range (capped at 14 deg, anti-alias)
%    B4  Charge ell       - topological charge, -1 .. +1 (0 = non-vortex J0)
%    B5  DriveScale       - effective amplitude 0..1 (SUB-1.6V operation)
%
%  DriveScale:  amplitude knob below the HV-rail floor. The TPC regulator
%  cannot hold below ~1.6 V, so to run "quieter" than that, keep the rail at
%  a clean few volts and scale TX.Apod by DriveScale. NOTE force ~ amplitude^2,
%  so DriveScale = 0.3 -> ~0.09x trapping force.
%
%  ANTI-ALIASING: pitch ~ 0.98 mm ~ 2*lambda. Axicon phase step per element =
%  2*pi*(p/lambda)*sin(beta) must stay < pi  ->  beta < ~14.6 deg. Default 12.
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

%% -------- Bessel-vortex design parameters (read by genTX) ---------------
Apex       = [0 0];        % axicon apex (x,y) [mm] -> lateral core position
BesselBeta = 14*pi/180;    % axicon half-angle [rad], <= 14 deg
Charge     = 1;            % topological charge ell (-1 .. +1)
ApodRadius = 5.4;          % circular support radius [mm]
ApodTaper  = 0.75;         % uniform-core fraction (soft raised-cosine edge)
DriveScale = 1.0;          % effective amplitude 0..1 (sub-1.6V knob)

kr       = (2*pi/lambda_mm)*sin(BesselBeta);
rRing_mm = 1.8412/kr;                              % ell=1 first J1 max
zMax_mm  = ApodRadius/tan(BesselBeta);
phiStep  = 360*(Trans.spacingMm/lambda_mm)*sin(BesselBeta);
fprintf('Bessel vortex: ring r ~ %.2f mm, range z ~ 0..%.0f mm\n', rRing_mm, zMax_mm);
fprintf('Axicon phase step per element: %.0f deg (keep < 180)\n', phiStep);

%% TW (quasi-CW burst)
nHalfCycles = 30;
TW(1).type       = 'parametric';
TW(1).Parameters = [Trans.frequency,1,nHalfCycles,1];
TW(1).equalize   = 0;

%% TPC (HV rail ceiling)
TPC(1).maxHighVoltage = 10;

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
lim = 10;

UI(1).Control = {'UserB1','Style','VsSlider','Label','Apex X (mm)', ...
    'SliderMinMaxVal',[-lim,lim,0],'SliderStep',[0.01/2,0.1/2],'ValueFormat','%3.0f'};
UI(1).Callback = @updateApexX;

UI(2).Control = {'UserB2','Style','VsSlider','Label','Apex Y (mm)', ...
    'SliderMinMaxVal',[-lim,lim,0],'SliderStep',[0.01/2,0.1/2],'ValueFormat','%3.0f'};
UI(2).Callback = @updateApexY;

UI(3).Control = {'UserB3','Style','VsSlider','Label','Axicon beta (deg)', ...
    'SliderMinMaxVal',[5,14,12],'SliderStep',[1/9,1/9],'ValueFormat','%2.0f'};
UI(3).Callback = @updateBeta;

% Topological charge: -1, 0, +1
UI(4).Control = {'UserB4','Style','VsSlider','Label','Charge ell', ...
    'SliderMinMaxVal',[-1,1,1],'SliderStep',[1/2,1/2],'ValueFormat','%2.0f'};
UI(4).Callback = @updateCharge;

% Effective amplitude (sub-1.6V operation)
UI(5).Control = {'UserB5','Style','VsSlider','Label','DriveScale', ...
    'SliderMinMaxVal',[0,1,1],'SliderStep',[0.01,0.05],'ValueFormat','%1.2f'};
UI(5).Callback = @updateDriveScale;

%% Save
name = '3MHz_IdealBesselVortex';
save(['Verasonics-Acoustic-Tweezer\Data Files\',name,'.mat']);
disp(['Program name: ', name])

% =========================================================================
%                              FUNCTIONS
% =========================================================================

function TX = genTX()
    Trans  = evalin('base','Trans');
    beta   = evalin('base','BesselBeta');
    ell    = evalin('base','Charge');
    Rap    = evalin('base','ApodRadius');
    tfrac  = evalin('base','ApodTaper');
    ds     = evalin('base','DriveScale');
    apex   = evalin('base','Apex');
    lam_mm = evalin('base','lambda_mm');
    N      = Trans.numelements;

    % element (x,y) in mm (handle wavelength/mm units)
    if isfield(Trans,'units') && strcmp(Trans.units,'wavelengths')
        pos = Trans.ElementPos(:,1:2)*lam_mm;
    else
        pos = Trans.ElementPos(:,1:2);
    end

    % circular uniform apodization (raised-cosine soft edge)
    rabs = hypot(pos(:,1),pos(:,2));
    w = ones(N,1);
    w(rabs > Rap) = 0;
    r0 = tfrac*Rap;
    edge = (rabs > r0) & (rabs <= Rap);
    w(edge) = 0.5*(1 + cos(pi*(rabs(edge)-r0)/(Rap-r0)));

    % single Bessel-vortex TX; DriveScale sets effective amplitude
    TX = struct('waveform',1, ...
                'Origin',zeros(1,3), ...
                'FocalPtMm',[apex 0], ...      % inert (delays computed directly)
                'Apod',(ds*w)', ...
                'Delay',zeros(1,N));
    TX.Delay = besselVortexDelay(pos, apex, beta, ell, lam_mm, w);
end

function D = besselVortexDelay(pos, apex, beta, ell, lam_mm, w)
    % axicon (converging cone) + helical phase, in wavelengths
    xr  = pos(:,1) - apex(1);
    yr  = pos(:,2) - apex(2);
    r   = hypot(xr,yr);
    phi = atan2(yr,xr);

    Dax = -(r*sin(beta))/lam_mm;             % outer fires first -> converge
    Dhe =  ell*mod(phi,2*pi)/(2*pi);         % helix (ell=0 -> plain J0 Bessel)
    D   = Dax + Dhe;

    act = w > 0;
    D   = D - min(D(act));                   % non-negative over active set
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
    Event(1).info      = 'Bessel vortex';
    Event(1).tx        = 1;
    Event(1).rcv       = 0;
    Event(1).recon     = 0;
    Event(1).process   = 0;
    Event(1).seqControl = [1,2];

    Event(2).info      = 'Bessel vortex';
    Event(2).tx        = 1;
    Event(2).rcv       = 0;
    Event(2).recon     = 0;
    Event(2).process   = 0;
    Event(2).seqControl = [1,2,3];
end

function updateApexX(~, ~, UIValue)
    apex = evalin('base','Apex'); apex(1) = UIValue;
    assignin('base','Apex',apex); updateTX();
end

function updateApexY(~, ~, UIValue)
    apex = evalin('base','Apex'); apex(2) = UIValue;
    assignin('base','Apex',apex); updateTX();
end

function updateBeta(~, ~, UIValue)
    assignin('base','BesselBeta',min(UIValue,14)*pi/180); updateTX();
end

function updateCharge(~, ~, UIValue)
    assignin('base','Charge',round(UIValue)); updateTX();
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

    apex = evalin('base','Apex');
    ds   = evalin('base','DriveScale');

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

    disp(['Apex (x,y) mm: ', num2str(apex), ...
          ' | beta = ', num2str(evalin('base','BesselBeta')*180/pi,'%.0f'), ' deg', ...
          ' | ell = ', num2str(evalin('base','Charge')), ...
          ' | DriveScale = ', num2str(ds,'%.2f'), ...
          ' | HV rail = ', num2str(hv,'%.2f'), ' V', ...
          ' | V_eff = ', num2str(Veff,'%.2f'), ' V-equiv', ...
          ' (force ~ ', num2str(ds^2,'%.3f'), 'x at this rail)']);
end
