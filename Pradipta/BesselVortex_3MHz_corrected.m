% =========================================================================
%  BesselVortex_3MHz_corrected.m
%  Verasonics Vantage 4.8.4 - single ideal uniform Bessel vortex tweezer
%  Verified against github.com/bemmens/Verasonics-Acoustic-Tweezer:
%    TransducerData/gen3MHz2D_Trans.m and SetUp Files/SetUp_3Mhz2D_MobileFocus.m
%
%  Field:  p(r,phi,z) ~ J_ell(k_r r) e^{i ell phi} e^{i k_z z}
%          k_r = k sin(beta),  k_z = k cos(beta)
%  Built from an AXICON (conical) delay law + helical phase on a circular
%  uniform-illumination subaperture of the 11x11 array (pitch 1.0 mm,
%  element width 0.8 mm, aperture 11 x 11 mm, Trans.units = 'mm').
%
%  CONTROLS (UserB1..B5)
%    B1  Apex X (mm)      - translate the Bessel core laterally (+/- 3 mm)
%    B2  Apex Y (mm)      - translate the Bessel core laterally (+/- 3 mm)
%    B3  Axicon beta (deg)- ring size / axial range (capped at 14 deg)
%    B4  Charge ell       - topological charge, -1 / 0 / +1
%    B5  DriveScale       - effective amplitude 0.02..1 (sub-1.6V operation)
%
%  ---------------- REPO-VERIFIED CONVENTIONS (kept as-is) ----------------
%  * Resource.Parameters.connector = 1 (repo convention; Trans.connector
%    is NOT used in this codebase / Vantage 4.8.4 setup style)
%  * numRcvChannels omitted: repo TX-only scripts run without it
%  * TX struct fields exactly {waveform, Origin, FocalPtMm, Apod, Delay};
%    FocalPtMm proven INERT when Delay is supplied manually (the repo's
%    plane-wave TX sets FocalPtMm then overwrites Delay with zeros)
%  * Trans.maxHighVoltage = 50 in the repo Trans file -> 10 V ceiling OK
%
%  ---------------- CORRECTIONS RELATIVE TO REPO / DRAFT ------------------
%  1) returnToMatlab added to the event loop. Without it 'update&Run'
%     Controls are never serviced on HARDWARE and all sliders are dead.
%     NOTE: the repo's own SetUp_3Mhz2D_MobileFocus.m has this same bug
%     (masked by simulateMode = 1).
%  2) PITCH: the repo array pitch is 1.0 mm (Trans.spacingMm = 1), not the
%     0.98 mm hard-coded in the draft. Pitch is now read from Trans.
%  3) REPO BUG FIXED AFTER LOAD: gen3MHz2D_Trans.m sets
%     Trans.spacing = wavelength/pitch (INVERTED). Correct value is
%     pitch/wavelength ~ 2.03 wavelengths. Repaired below.
%  4) REPO BUG FIXED AFTER LOAD: Trans.ElementSens contains NaN at
%     theta = 0 (sin(0)/0). Repaired with a proper sinc form.
%  5) GRATING LOBES (honest statement): pitch = 1.0 mm ~ 2*lambda. The
%     beta cap below only keeps the SAMPLED axicon phase unambiguous
%     (p*k_r <= pi -> beta < 14.3 deg). It does NOT suppress grating
%     lobes: a spurious propagating cone exists at
%     sin(theta_g) = sin(beta) - lambda/p (~ -16.6 deg at beta = 12 deg).
%     Element directivity (w = 0.8 mm ~ 1.6 lambda) attenuates it only
%     partially. Validate the trap field with a hydrophone scan.
%  6) DriveScale is implemented by the tri-state pulser as per-half-cycle
%     PWM, NOT analog scaling. At ~3 MHz the half period is ~42 ticks of
%     the 250 MHz clock, so Apod is quantized in steps of ~1/42 ~ 0.024.
%     Floor at 0.02 (all-zero Apod TX may be rejected; force ~ ds^2 holds
%     for the fundamental only).
%  7) Apodization window TRAVELS WITH THE APEX (symmetric cone
%     illumination); apex clamped to +/- 3 mm (elements span +/- 5 mm).
%  8) TW duty = 0.67 (repo uses 1): suppresses the 3rd harmonic, which a
%     2-lambda-pitch array samples even worse than the fundamental.
%  9) Frequency snapping: 3 MHz is not synthesizable from the 250 MHz
%     master clock; VSX snaps to 250/round(250/3) = 250/83 ~ 3.0120 MHz.
%     Delays are in wavelengths so they rescale consistently; k_r and the
%     ring radius shift ~0.4% (printed for awareness).
% 10) simulateMode is a prominent switch at the top. Set to 0 for bench.
% =========================================================================

clear all  %#ok<CLALL>

%% ------------------------------ MODE ------------------------------------
SIMULATE = 1;    % <<<< SET TO 0 FOR HARDWARE >>>>

%% Resource  (repo conventions: SetUp_3Mhz2D_MobileFocus.m)
Resource.Parameters.numTransmit  = 121;
Resource.Parameters.connector    = 1;        % repo convention (NOT Trans.connector)
Resource.Parameters.speedOfSound = 1481;     % m/s (water, ~20 C)
Resource.Parameters.simulateMode = SIMULATE;
Resource.System.UTA = '160-SH';              % pairs with Trans.connType = 12 in repo

%% Trans  (11x11, pitch 1.0 mm, units 'mm', connType 12, maxHV 50)
load 3MHz2D_Trans.mat

%% Physical parameters
% Actual synthesized frequency (250 MHz master clock)
fReq_MHz = Trans.frequency;                  % 3 MHz in repo Trans file
fAct_MHz = 250/round(250/fReq_MHz);          % 250/83 ~ 3.0120 MHz
wavelength = Resource.Parameters.speedOfSound/(fAct_MHz*1e6); % m
lambda_mm  = wavelength*1e3;                                  % mm
fprintf('Requested f = %.4f MHz, synthesized f = %.4f MHz (lambda = %.4f mm)\n', ...
        fReq_MHz, fAct_MHz, lambda_mm);

% Element pitch from the Trans structure (repo: Trans.spacingMm = 1.0)
pitch_mm = Trans.spacingMm;

% ---- REPO BUG REPAIRS (post-load) ----
% (a) gen3MHz2D_Trans.m computes Trans.spacing = wavelength/pitch (inverted).
%     Correct definition: element spacing in WAVELENGTHS = pitch/lambda.
Trans.spacing = pitch_mm/lambda_mm;          % ~ 2.03 wavelengths
% (b) Trans.ElementSens has NaN at theta = 0 (sin(0)/0). Rebuild with the
%     standard hard-baffle form: cos(theta)*sinc((w/lambda)*sin(theta)),
%     using the ACTUAL w/lambda = 0.8/0.4937 ~ 1.62 (repo used 0.8).
Theta = (-pi/2:pi/100:pi/2);
wOverLam = Trans.elementWidth/lambda_mm;
Trans.ElementSens = abs(cos(Theta).*sinc(wOverLam*sin(Theta)));  % sinc(x)=sin(pi x)/(pi x), finite at 0

% HV ceiling sanity: VSX enforces min(Trans.maxHighVoltage, TPC ceiling)
if ~isfield(Trans,'maxHighVoltage') || Trans.maxHighVoltage < 10
    warning('Trans.maxHighVoltage caps the rail below the requested 10 V ceiling.');
end

%% -------- Bessel-vortex design parameters (read by genTX) ---------------
ApexLim    = 3;            % apex slider clamp [mm] (elements span +/- 5 mm)
Apex       = [0 0];        % axicon apex (x,y) [mm] -> lateral core position
BesselBeta = 12*pi/180;    % axicon half-angle [rad], <= 14 deg
Charge     = 1;            % topological charge ell (-1, 0, +1)
ApodRadius = 5.4;          % circular support radius [mm]
ApodTaper  = 0.75;         % uniform-core fraction (raised-cosine edge)
DriveScale = 1.0;          % effective amplitude 0.02..1 (PWM-quantized ~0.024)

kr       = (2*pi/lambda_mm)*sin(BesselBeta);
zMax_mm  = ApodRadius/tan(BesselBeta);
if Charge == 0
    fprintf('J0 beam: central max on axis, first null r ~ %.2f mm, range z ~ 0..%.0f mm\n', ...
            2.4048/kr, zMax_mm);
else
    fprintf('Bessel vortex |ell|=1: ring r ~ %.2f mm, range z ~ 0..%.0f mm\n', ...
            1.8412/kr, zMax_mm);
end

% Sampled-phase ambiguity check (NOT grating-lobe suppression):
phiStep = 360*(pitch_mm/lambda_mm)*sin(BesselBeta);
fprintf('Axicon phase step per element: %.0f deg (keep < 180 for unambiguous sampling)\n', phiStep);

% Grating-lobe cone (honest report; exists whenever pitch > lambda/2):
sg = sin(BesselBeta) - lambda_mm/pitch_mm;
if abs(sg) <= 1
    fprintf(['WARNING: grating-lobe cone at %.1f deg (pitch = %.2f mm = %.2f lambda).\n' ...
             '         Element directivity gives only partial suppression. Verify with hydrophone.\n'], ...
            asind(sg), pitch_mm, pitch_mm/lambda_mm);
end

%% TW (quasi-CW burst)
nHalfCycles = 30;
TW(1).type       = 'parametric';
TW(1).Parameters = [Trans.frequency, 0.67, nHalfCycles, 1];  % duty 0.67 (repo uses 1): 3rd-harmonic suppression
TW(1).equalize   = 0;

%% TPC (HV rail ceiling; Trans.maxHighVoltage = 50 in repo, so 10 V governs)
TPC(1).maxHighVoltage = 10;

%% TX
TX = genTX();

%% Sequence
TTNB = 20;   % us
period_s  = 1/(fAct_MHz*1e6);
dutyCycle = ((nHalfCycles/2)*period_s)/(TTNB*1e-6);
fprintf('Sequence duty cycle: %.2f%%\n', dutyCycle*100);

SeqControl = genSeqControl(TTNB);
Event      = genEvent();

%% UI
UI(1).Control = {'UserB1','Style','VsSlider','Label','Apex X (mm)', ...
    'SliderMinMaxVal',[-ApexLim,ApexLim,0],'SliderStep',[0.05/(2*ApexLim),0.5/(2*ApexLim)],'ValueFormat','%2.1f'};
UI(1).Callback = @updateApexX;

UI(2).Control = {'UserB2','Style','VsSlider','Label','Apex Y (mm)', ...
    'SliderMinMaxVal',[-ApexLim,ApexLim,0],'SliderStep',[0.05/(2*ApexLim),0.5/(2*ApexLim)],'ValueFormat','%2.1f'};
UI(2).Callback = @updateApexY;

UI(3).Control = {'UserB3','Style','VsSlider','Label','Axicon beta (deg)', ...
    'SliderMinMaxVal',[5,14,12],'SliderStep',[1/9,1/9],'ValueFormat','%2.0f'};
UI(3).Callback = @updateBeta;

UI(4).Control = {'UserB4','Style','VsSlider','Label','Charge ell', ...
    'SliderMinMaxVal',[-1,1,1],'SliderStep',[1/2,1/2],'ValueFormat','%2.0f'};
UI(4).Callback = @updateCharge;

% DriveScale: PWM-quantized to ~1/42 steps at 3 MHz; floor 0.02
UI(5).Control = {'UserB5','Style','VsSlider','Label','DriveScale', ...
    'SliderMinMaxVal',[0.02,1,1],'SliderStep',[0.05/0.98,0.10/0.98],'ValueFormat','%1.2f'};
UI(5).Callback = @updateDriveScale;

%% Save (repo layout: 'Verasonics-Acoustic-Tweezer\Data Files\')
name = 'BesselVortex_3MHz_corrected';
saveDir = fullfile('Verasonics-Acoustic-Tweezer','Data Files');
if ~exist(saveDir,'dir'), mkdir(saveDir); end
save(fullfile(saveDir,[name,'.mat']));
disp(['Program name: ', name])
if SIMULATE
    disp('*** simulateMode = 1 : set SIMULATE = 0 for hardware operation ***');
end

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

    % element (x,y) in mm; repo Trans has units = 'mm', ElementPos = [x y z az el]
    if isfield(Trans,'units') && strcmp(Trans.units,'wavelengths')
        pos = Trans.ElementPos(:,1:2)*lam_mm;
    else
        pos = Trans.ElementPos(:,1:2);
    end

    % circular apodization CENTERED ON THE APEX (window travels with core),
    % raised-cosine soft edge; physical aperture bounds the support
    rabs = hypot(pos(:,1)-apex(1), pos(:,2)-apex(2));
    w = ones(N,1);
    w(rabs > Rap) = 0;
    r0 = tfrac*Rap;
    edge = (rabs > r0) & (rabs <= Rap);
    w(edge) = 0.5*(1 + cos(pi*(rabs(edge)-r0)/(Rap-r0)));

    if ~any(w > 0)
        error('genTX: apodization window has no active elements (apex out of aperture).');
    end

    % Single Bessel-vortex TX. Field set mirrors the repo's working structs
    % {waveform, Origin, FocalPtMm, Apod, Delay}; FocalPtMm is INERT because
    % Delay is supplied manually (proven by the repo's plane-wave TX).
    TX = struct('waveform',1, ...
                'Origin',zeros(1,3), ...
                'FocalPtMm',[apex 0], ...
                'Apod',(max(ds,0.02)*w)', ...
                'Delay',zeros(1,N));
    TX.Delay = besselVortexDelay(pos, apex, beta, ell, lam_mm, w);
end

function D = besselVortexDelay(pos, apex, beta, ell, lam_mm, w)
    % axicon (converging cone) + helical phase, in WAVELENGTHS
    % Axial check: arrival on axis t = R sin(beta)/c + z cos(beta)/c
    % -> axial phase speed c/cos(beta), i.e. k_z = k cos(beta). (Verified.)
    xr  = pos(:,1) - apex(1);
    yr  = pos(:,2) - apex(2);
    r   = hypot(xr,yr);
    phi = atan2(yr,xr);

    Dax = -(r*sin(beta))/lam_mm;             % outer fires first -> converging cone
    Dhe =  ell*mod(phi,2*pi)/(2*pi);         % helix; ell=0 -> plain J0
    D   = Dax + Dhe;

    act = w > 0;
    D   = D - min(D(act));                   % non-negative over ACTIVE set
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
    SeqControl(4).command   = 'returnToMatlab';   % REQUIRED on hardware: services UI Controls
end

function Event = genEvent()
    Event(1).info      = 'Bessel vortex';
    Event(1).tx        = 1;
    Event(1).rcv       = 0;
    Event(1).recon     = 0;
    Event(1).process   = 0;
    Event(1).seqControl = [1,2];

    Event(2).info      = 'Bessel vortex + returnToMatlab';
    Event(2).tx        = 1;
    Event(2).rcv       = 0;
    Event(2).recon     = 0;
    Event(2).process   = 0;
    Event(2).seqControl = [1,2,4,3];   % returnToMatlab BEFORE the jump
end

function updateApexX(~, ~, UIValue)
    lim  = evalin('base','ApexLim');
    apex = evalin('base','Apex'); apex(1) = max(-lim,min(lim,UIValue));
    assignin('base','Apex',apex); updateTX();
end

function updateApexY(~, ~, UIValue)
    lim  = evalin('base','ApexLim');
    apex = evalin('base','Apex'); apex(2) = max(-lim,min(lim,UIValue));
    assignin('base','Apex',apex); updateTX();
end

function updateBeta(~, ~, UIValue)
    assignin('base','BesselBeta',min(UIValue,14)*pi/180); updateTX();
end

function updateCharge(~, ~, UIValue)
    assignin('base','Charge',max(-1,min(1,round(UIValue)))); updateTX();
end

function updateDriveScale(~, ~, UIValue)
    % floor at 0.02 (all-zero Apod TX may be rejected; PWM step ~ 0.024)
    assignin('base','DriveScale',max(0.02,min(1,UIValue))); updateTX();
end

function updateTX()
    TX = genTX();
    assignin('base','TX',TX);

    Control(1).Command    = 'update&Run';
    Control(1).Parameters = {'TX'};
    assignin('base','Control',Control);

    apex = evalin('base','Apex');
    ds   = evalin('base','DriveScale');

    % Current HV rail from TPC (graceful fallback to the ceiling)
    hv = NaN;
    if evalin('base','exist(''TPC'',''var'')')
        TPC = evalin('base','TPC');
        if isfield(TPC,'hv') && ~isempty(TPC(1).hv)
            hv = TPC(1).hv;                 % runtime rail voltage [V]
        elseif isfield(TPC,'maxHighVoltage')
            hv = TPC(1).maxHighVoltage;     % ceiling, if runtime hv not set
        end
    end
    Veff = ds*hv;   % fundamental-amplitude proxy [V-equiv]; exact only for ds=1

    disp(['Apex (x,y) mm: ', num2str(apex), ...
          ' | beta = ', num2str(evalin('base','BesselBeta')*180/pi,'%.0f'), ' deg', ...
          ' | ell = ', num2str(evalin('base','Charge')), ...
          ' | DriveScale = ', num2str(ds,'%.2f'), ' (PWM step ~0.024)', ...
          ' | HV rail = ', num2str(hv,'%.2f'), ' V', ...
          ' | V_eff ~ ', num2str(Veff,'%.2f'), ' V-equiv', ...
          ' (force ~ ', num2str(ds^2,'%.3f'), 'x at this rail)']);
end
