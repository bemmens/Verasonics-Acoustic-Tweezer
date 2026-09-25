% BesselVortex_3MHz_Corrected.m
% Configuration generator for the custom 121-element Verasonics array.
% Run this script in the MATLAB base workspace, then enter VSX when ready.
% The script sets filename and adds the generated MAT folder to the path.
% This script does not start VSX or transmit by itself.
%
% Finite-aperture axicon + helical phase approximation to a Bessel vortex.
% The aperture and its sampling do not guarantee an ideal Bessel field.
% TX.Delay is in periods of Trans.frequency (Verasonics wavelength units).
%
% Changes from 3MHz_IdealBesselVortex.m:
%   Hardware mode for acquisition; original 10 V ceiling and timing retained.
%   A vortex-axis element is disabled when Charge is nonzero.
%   Apex controls limited to +/-0.5 mm, with decimal readout.
%   No substitution of voltage ceiling for TPC.hv; no uncalibrated force claim.
%   Explicit transducer-file/units validation and an unambiguous output path.
%
% The requested duty cycle is nominal: verify the actual acoustic pulse train.
% DriveScale is an apodization command, not calibrated pressure or voltage.

clearvars

%% Resource and configuration location
scriptDir = fileparts(mfilename('fullpath'));
addpath(scriptDir);                    % keep callbacks available to VSX
Resource.Parameters.numTransmit = 121;
Resource.Parameters.connector = 1;
Resource.Parameters.speedOfSound = 1481; % water [m/s]
Resource.Parameters.simulateMode = 0;   % 0 hardware; set 1 for VSX simulation
Resource.System.UTA = '160-SH';

%% Load the actual custom transducer definition
transFile = fullfile(scriptDir, '3MHz2D_Trans.mat');
if ~isfile(transFile)
    transFile = which('3MHz2D_Trans.mat');
end
if isempty(transFile) || ~isfile(transFile)
    error('BesselVortex:MissingTransducer', ...
        ['Place the actual 3MHz2D_Trans.mat beside this script or on the ', ...
         'MATLAB path. A generated substitute must not be used on hardware.']);
end
transData = load(transFile, 'Trans');
assert(isfield(transData,'Trans'), 'BesselVortex:MissingTransStruct', ...
    'The transducer MAT file must contain the Trans structure.');
Trans = transData.Trans;
clear transData
required = {'frequency','numelements','ElementPos','units'};
assert(all(isfield(Trans,required)), 'BesselVortex:TransducerFields', ...
    'Trans must define frequency, numelements, ElementPos and units.');
validateattributes(Trans.frequency, {'numeric'}, ...
    {'scalar','real','finite','positive'});
assert(Trans.numelements == Resource.Parameters.numTransmit, ...
    'BesselVortex:ElementCount', 'Expected the actual 121-element array.');
assert(size(Trans.ElementPos,1) == Trans.numelements && ...
       size(Trans.ElementPos,2) >= 2, ...
    'BesselVortex:Positions', 'ElementPos must contain one row per element.');
assert(any(strcmpi(Trans.units,{'mm','wavelengths'})), ...
    'BesselVortex:Units', 'Trans.units must explicitly be mm or wavelengths.');
fprintf('Transducer definition: %s\n', transFile);
fprintf('Configured mode: %d (0 hardware, 1 simulation)\n', ...
    Resource.Parameters.simulateMode);

%% Bessel-vortex parameters
lambda_mm = 1e3*Resource.Parameters.speedOfSound/(Trans.frequency*1e6);
Apex = [0 0];                         % lateral apex [mm]
ApexLimit = 0.5;                      % diagnostic translation limit [mm]
BesselBeta = deg2rad(12);
Charge = 1;                           % -1, 0, +1
ApodRadius = 5.4;                     % fixed circular aperture radius [mm]
ApodTaper = 0.75;                     % untapered central fraction
DriveScale = 1.0;                     % requested TX.Apod scaling, 0..1

kr = (2*pi/lambda_mm)*sin(BesselBeta);
rRing_mm = 1.8412/kr;                 % ideal J1 first maximum
zMax_mm = ApodRadius/tan(BesselBeta);  % geometric estimate, not uniform range
fprintf('Ideal J1 ring radius %.3f mm; geometric axial range %.2f mm.\n', ...
    rRing_mm,zMax_mm);
fprintf(['The beta cap limits the radial phase gradient only; it does not ', ...
    'guarantee absence of grating lobes or adequate helix sampling.\n']);

%% Waveform and voltage ceiling (unchanged excitation request)
nHalfCycles = 30;                     % 15 cycles, 5 us if frequency is 3 MHz
TW(1).type = 'parametric';
TW(1).Parameters = [Trans.frequency,1,nHalfCycles,1];
TW(1).equalize = 0;
TPC(1).maxHighVoltage = 10;           % ceiling only; not a voltage readback
fprintf('TPC ceiling %.1f V; set/check actual voltage in the active VSX profile.\n', ...
    TPC(1).maxHighVoltage);

%% Transmit and sequence
TX = genTX();
TTNB = 20;                           % requested inter-transmit interval [us]
burst_us = (nHalfCycles/2)/Trans.frequency;
dutyCycle = burst_us/TTNB;
assert(burst_us < TTNB, 'BesselVortex:PulseTiming', ...
    'Burst duration must be shorter than the requested transmit interval.');
delaySpan_us = max(TX.Delay)/Trans.frequency;
assert(delaySpan_us + burst_us < TTNB, 'BesselVortex:DelayTiming', ...
    'Burst plus element-delay span exceeds the requested interval.');
fprintf('Burst %.3f us; nominal PRF %.1f kHz; nominal duty %.2f%%.\n', ...
    burst_us,1e3/TTNB,100*dutyCycle);
fprintf('Measure actual repetition and gaps; these are requested timing values.\n');
SeqControl = genSeqControl(TTNB);
Event = genEvent();

%% User controls
% SliderStep is a fraction of the complete range: 0.01 and 0.1 mm steps.
apexStep = [0.01 0.1]/(2*ApexLimit);
UI(1).Control = {'UserB1','Style','VsSlider','Label','Apex X (mm)', ...
    'SliderMinMaxVal',[-ApexLimit,ApexLimit,Apex(1)], ...
    'SliderStep',apexStep,'ValueFormat','%1.2f'};
UI(1).Callback = @updateApexX;
UI(2).Control = {'UserB2','Style','VsSlider','Label','Apex Y (mm)', ...
    'SliderMinMaxVal',[-ApexLimit,ApexLimit,Apex(2)], ...
    'SliderStep',apexStep,'ValueFormat','%1.2f'};
UI(2).Callback = @updateApexY;
UI(3).Control = {'UserB3','Style','VsSlider','Label','Axicon beta (deg)', ...
    'SliderMinMaxVal',[5,14,rad2deg(BesselBeta)], ...
    'SliderStep',[1/9,1/9],'ValueFormat','%2.0f'};
UI(3).Callback = @updateBeta;
UI(4).Control = {'UserB4','Style','VsSlider','Label','Charge ell', ...
    'SliderMinMaxVal',[-1,1,Charge], ...
    'SliderStep',[1/2,1/2],'ValueFormat','%2.0f'};
UI(4).Callback = @updateCharge;
UI(5).Control = {'UserB5','Style','VsSlider','Label','Apod scale', ...
    'SliderMinMaxVal',[0,1,DriveScale], ...
    'SliderStep',[0.01,0.05],'ValueFormat','%1.2f'};
UI(5).Callback = @updateDriveScale;

%% Save beside this script, with a different configuration name
name = 'BesselVortex_3MHz_Corrected';
outputDir = fullfile(scriptDir,'Data Files');
if ~isfolder(outputDir), mkdir(outputDir); end
outputFile = fullfile(outputDir,[name '.mat']);
save(outputFile, 'Resource','Trans','TW','TPC','TX','SeqControl','Event','UI', ...
    'Apex','ApexLimit','BesselBeta','Charge','ApodRadius','ApodTaper', ...
    'DriveScale','lambda_mm','nHalfCycles','TTNB','dutyCycle','name', ...
    'scriptDir','transFile');
% VSX uses the base-workspace variable filename to select its configuration.
% Use a space-free basename on the MATLAB path so the launcher does not need
% to parse a full path containing spaces.
addpath(outputDir,'-begin');
filename = [name '.mat'];
resolvedFile = which(filename);
if ~strcmpi(resolvedFile,outputFile)
    error('BesselVortex:ConfigurationPath', ...
        'MAT-file lookup resolved to "%s", expected "%s".',resolvedFile,outputFile);
end
savedVariables = whos('-file',outputFile);
if ~all(ismember({'Resource','Trans','TW','TX','Event','SeqControl'}, ...
        {savedVariables.name}))
    error('BesselVortex:ConfigurationContents','Saved configuration is incomplete.');
end
fprintf('Configuration saved and found on MATLAB path: %s\n',outputFile);
fprintf('VSX filename = ''%s''\n',filename);
fprintf('When ready for the configured hardware sequence, enter: VSX\n');

%% Local functions
function TX = genTX()
    Trans = evalin('base','Trans');
    beta = evalin('base','BesselBeta');
    ell = evalin('base','Charge');
    Rap = evalin('base','ApodRadius');
    tfrac = evalin('base','ApodTaper');
    ds = evalin('base','DriveScale');
    apex = evalin('base','Apex');
    lam_mm = evalin('base','lambda_mm');
    N = Trans.numelements;
    pos = Trans.ElementPos(:,1:2);
    if strcmpi(Trans.units,'wavelengths'), pos = pos*lam_mm; end
    validateattributes(pos,{'numeric'},{'real','finite'});
    validateattributes(tfrac,{'numeric'},{'scalar','>=',0,'<',1});

    rabs = hypot(pos(:,1),pos(:,2));
    w = ones(N,1);
    w(rabs > Rap) = 0;
    r0 = tfrac*Rap;
    edge = rabs > r0 & rabs <= Rap;
    w(edge) = 0.5*(1+cos(pi*(rabs(edge)-r0)/(Rap-r0)));
    if ell ~= 0
        % Phase is undefined exactly at the vortex apex. Do not assign that
        % element an arbitrary full-strength phase via atan2(0,0).
        rAxis = hypot(pos(:,1)-apex(1),pos(:,2)-apex(2));
        w(rAxis < 1e-9) = 0;
    end
    assert(any(w > 0),'BesselVortex:EmptyAperture','No active aperture elements.');
    TX = struct('waveform',1,'Origin',zeros(1,3), ...
        'FocalPtMm',[apex 0], ... % metadata only; delays set explicitly below
        'Apod',(ds*w)','Delay',zeros(1,N));
    TX.Delay = besselVortexDelay(pos,apex,beta,ell,lam_mm,w);
end

function D = besselVortexDelay(pos,apex,beta,ell,lam_mm,w)
    xr = pos(:,1)-apex(1);
    yr = pos(:,2)-apex(2);
    r = hypot(xr,yr);
    phi = atan2(yr,xr);
    Dax = -r*sin(beta)/lam_mm;       % outer elements start earlier
    Dhe = ell*mod(phi,2*pi)/(2*pi); % original handedness; verify with phase map
    D = Dax+Dhe;
    act = w > 0;
    D = D-min(D(act));
    D(~act) = 0;
    D = D';                        % wavelength/time units, not microseconds
end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command = 'triggerOut';
    SeqControl(2).command = 'timeToNextAcq';
    SeqControl(2).argument = TTNB;
    SeqControl(3).command = 'jump';
    SeqControl(3).argument = 1;
    SeqControl(3).condition = 'exitAfterJump'; % preserve existing loop semantics
end

function Event = genEvent()
    Event(1) = struct('info','Bessel vortex','tx',1,'rcv',0, ...
        'recon',0,'process',0,'seqControl',[1,2]);
    Event(2) = Event(1);
    Event(2).seqControl = [1,2,3];
end

function updateApexX(~,~,UIValue)
    apex = evalin('base','Apex');
    lim = evalin('base','ApexLimit');
    apex(1) = max(-lim,min(lim,UIValue));
    assignin('base','Apex',apex);
    updateTX();
end

function updateApexY(~,~,UIValue)
    apex = evalin('base','Apex');
    lim = evalin('base','ApexLimit');
    apex(2) = max(-lim,min(lim,UIValue));
    assignin('base','Apex',apex);
    updateTX();
end

function updateBeta(~,~,UIValue)
    assignin('base','BesselBeta',deg2rad(max(5,min(UIValue,14))));
    updateTX();
end

function updateCharge(~,~,UIValue)
    assignin('base','Charge',max(-1,min(1,round(UIValue))));
    updateTX();
end

function updateDriveScale(~,~,UIValue)
    assignin('base','DriveScale',max(0,min(1,UIValue)));
    updateTX();
end

function updateTX()
    TX = genTX();
    freq = evalin('base','Trans.frequency');
    interval = evalin('base','TTNB');
    halfCycles = evalin('base','nHalfCycles');
    assert((max(TX.Delay)+halfCycles/2)/freq < interval, ...
        'BesselVortex:DelayTiming','Updated delays exceed transmit interval.');
    assignin('base','TX',TX);
    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'TX'};
    assignin('base','Control',Control);

    hv = NaN;
    if evalin('base','exist(''TPC'',''var'')')
        TPC = evalin('base','TPC');
        if ~isempty(TPC) && isfield(TPC,'hv') && ...
                isnumeric(TPC(1).hv) && isscalar(TPC(1).hv) && isfinite(TPC(1).hv)
            hv = TPC(1).hv;
        end
    end
    if isnan(hv)
        hvText = 'unavailable (ceiling is not readback)';
    else
        hvText = sprintf('%.2f V (TPC.hv; verify active profile)',hv);
    end
    apex = evalin('base','Apex');
    fprintf(['Apex [%.2f %.2f] mm | beta %.1f deg | charge %d | ', ...
        'apod scale %.2f | TPC voltage %s\n'], ...
        apex(1),apex(2),rad2deg(evalin('base','BesselBeta')), ...
        evalin('base','Charge'),evalin('base','DriveScale'),hvText);
end
