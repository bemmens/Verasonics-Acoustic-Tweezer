clear all

% Simple plane wave generation for PogoPin testing

%% Generate Resource
Resource.Parameters.numTransmit = 121; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use.
Resource.Parameters.speedOfSound = 1481;
Resource.Parameters.simulateMode = 1; % runs script in simulate mode

Resource.System.UTA = '160-SH';

%% Generate Trans
load DIYMk1Trans % Load transducer model

%% Physical Parameters
wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m

%% Generate TW
nHalfCycles = 20;
TW(1).type = 'parametric';
TW(1).Parameters = [1.05,1,nHalfCycles,1]; % MHz, PulseWidth, NHalfCycles,polarity
TW(1).equalize = 0;

%% Set Transmit Power
TPC(1).maxHighVoltage = 10; % Set max voltage

%% Specify TX structure array.
TTNB = 20; % us

% GUI Variables
FocalPtMm = [0 0 50];

ScAT_Path = 'ScAT_Paths/Dove_25mm_384Points.csv';
ScAT_Rotation = 0;

VortexPeriod = 0; %dummy
r = 0; %dummy

% Calculate the duty cycle of the sequence
period = 1 / (Trans.frequency * 1e6); %in seconds
dutyCycle = ((nHalfCycles/2) * period)/(TTNB*1e-6); % Duty cycle calculation
fprintf('Duty cycle: %.2f%%\n', dutyCycle * 100);

[TX, nFrames] = genTX(TTNB, FocalPtMm, ScAT_Path, ScAT_Rotation);

%% Specify sequence events.
SeqControl = genSeqControl(TTNB);
Event = genEvent(nFrames);

%% UI Controls

xlim = 10;
ylim = xlim;
zlim = 100;

% X-Axis Slider for TX Focal Point
UI(1).Control = {'UserB5', 'Style', 'VsSlider', ...
    'Label', 'X [mm]', ...
    'SliderMinMaxVal', [-xlim, xlim, 0], ... % X range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.0f'};
UI(1).Callback = @updateFocalPointX;

% Y-Axis Slider for TX Focal Point
UI(2).Control = {'UserB4', 'Style', 'VsSlider', ...
    'Label', 'Y [mm]', ...
    'SliderMinMaxVal', [-ylim, ylim, 0], ... % Y range: -20mm to 20mm, default 0
    'SliderStep', [0.01/2, 0.1/2], ...
    'ValueFormat', '%3.0f'};
UI(2).Callback = @updateFocalPointY;

% Z-Axis Slider for TX Focal Point
UI(3).Control = {'UserB3', 'Style', 'VsSlider', ...
    'Label', 'Z [mm]', ...
    'SliderMinMaxVal', [0, zlim, 50], ... % Z range: 20mm to 100mm, default 50
    'SliderStep', [0.01, 0.1], ...
    'ValueFormat', '%3.0f'};
UI(3).Callback = @updateFocalPointZ;

% ScAT path input
UI(4).Control = {'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.20, 0.05, 0.58, 0.04], ...
    'String', ScAT_Path, ...
    'HorizontalAlignment', 'left', ...
    'Tag', 'ScATPathEdit', ...
    'TooltipString', 'Enter an ScAT CSV path, then click Reload ScAT Path'};

% Reload ScAT path
UI(5).Control = {'UserB6', 'Style', 'VsPushButton', ...
    'Label', 'Reload ScAT Path'};
UI(5).Callback = @reloadScATPath;

% Rotate ScAT path counterclockwise by 90 degrees
UI(6).Control = {'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0.80, 0.05, 0.18, 0.04], ...
    'String', 'Rotate 90 CCW', ...
    'Callback', @rotateScATPath};

%% Save all the structures to a .mat file.
name = 'DIYMk2_ScAT_From_File';
save(['Verasonics-Acoustic-Tweezer\Data Files\',name,'.mat']);
disp(['Program name: ', name])

%% Functions

function reloadScATPath(hObject, ~)
    ScAT_Rotation = evalin('base', 'ScAT_Rotation');
    refreshScATPath(hObject, ScAT_Rotation);
end

function rotateScATPath(hObject, ~)
    ScAT_Rotation = mod(evalin('base', 'ScAT_Rotation') + 90, 360);
    refreshScATPath(hObject, ScAT_Rotation);
end

function refreshScATPath(hObject, ScAT_Rotation)
    pathEdit = findobj(ancestor(hObject, 'figure'), 'Tag', 'ScATPathEdit');
    if isempty(pathEdit)
        error('ScAT path input control was not found.');
    end
    ScAT_Path = strtrim(get(pathEdit, 'String'));
    if isempty(ScAT_Path)
        error('ScAT path cannot be empty.');
    end
    if exist(ScAT_Path, 'file') ~= 2
        error('ScAT path file not found: %s', ScAT_Path);
    end

    TTNB = evalin('base', 'TTNB');
    FocalPtMm = evalin('base', 'FocalPtMm');

    [TX, nFrames] = genTX(TTNB, FocalPtMm, ScAT_Path, ScAT_Rotation);
    Event = genEvent(nFrames);

    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'TX'};
    Control(2).Command = 'update&Run';
    Control(2).Parameters = {'Event'};

    assignin('base', 'ScAT_Path', ScAT_Path);
    assignin('base', 'ScAT_Rotation', ScAT_Rotation);
    assignin('base', 'TX', TX);
    assignin('base', 'Event', Event);
    assignin('base', 'Control', Control);
end

function updateFocalPointX(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    VortexPeriod = evalin('base','VortexPeriod');
    r = evalin('base','r');
    % Update only the X coordinate of the focal point
    FocalPtMm(1) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(r, VortexPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end

function updateFocalPointY(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    VortexPeriod = evalin('base','VortexPeriod');
    r = evalin('base','r');
    % Update only the Y coordinate of the focal point
    FocalPtMm(2) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(r, VortexPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end

function updateFocalPointZ(~, ~, UIValue)
    FocalPtMm = evalin('base', 'FocalPtMm');
    VortexPeriod = evalin('base','VortexPeriod');
    r = evalin('base','r');
    % Update only the Z coordinate of the focal point
    FocalPtMm(3) = UIValue;
    assignin('base', 'FocalPtMm', FocalPtMm);
    % Update system
    updateSequence(r, VortexPeriod, FocalPtMm);
    % Print new Sequence Parameters
    disp(['Current Focal Point: ', num2str(FocalPtMm)]);
end


function [TX, nFrames] = genTX(TTNB, FocalPtMm, ScAT_Path, ScAT_Rotation)

    Trans = evalin('base','Trans');
    pathCoordinates = readmatrix(ScAT_Path);
    if size(pathCoordinates, 2) < 2
        error('ScAT path file must contain at least two columns for X and Y coordinates.');
    end
    pathCoordinates = pathCoordinates(:,1:2);
    pathCoordinates = pathCoordinates(all(isfinite(pathCoordinates), 2), :);
    switch mod(ScAT_Rotation, 360)
        case 90
            pathCoordinates = [-pathCoordinates(:,2), pathCoordinates(:,1)];
        case 180
            pathCoordinates = -pathCoordinates;
        case 270
            pathCoordinates = [pathCoordinates(:,2), -pathCoordinates(:,1)];
    end
    if isempty(pathCoordinates)
        error('ScAT path file contains no valid X/Y coordinates.');
    end

    nFrames = size(pathCoordinates, 1);
    fpoints(:,1:2) = pathCoordinates.*1e3;
    fpoints(:,3) = FocalPtMm(3);

    disp(['nFrames: ',num2str(nFrames)])
    disp(['Period: ',num2str(nFrames*TTNB),'us'])

    figure(1)
    scatter(fpoints(:,1),fpoints(:,2))
    axis('equal')

    lensFocalPointMm = [0 0 50];

    wavelength = evalin('base','wavelength');
    k = 2*pi/wavelength;

    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,nFrames); 
    
    for i = 1:nFrames
        TX(i).FocalPtMm = fpoints(i,:);
%         TX(i).Delay = computeTXDelays(TX(i));
        TX(i).Delay = addHybridFocus(Trans.ElementPos,fpoints(i,:),lensFocalPointMm,k);
        
    end
end

function SeqControl = genSeqControl(TTNB)
    SeqControl(1).command = 'triggerOut';
    SeqControl(2).command = 'timeToNextAcq';
    SeqControl(2).argument = TTNB;
    SeqControl(3).command = 'jump';
    SeqControl(3).argument = 1;
    SeqControl(3).condition = 'exitAfterJump';
end

function Event = genEvent(nFrames)

    Event = repmat(struct('info', 'TX', ...
                      'tx', 1, ...
                      'rcv', 0, ...
                      'recon', 0, ...
                      'process', 0, ...
                      'seqControl', [2]), ...
                      1,nFrames*2);

    Event(1).seqControl = [1,2];
    Event(nFrames).seqControl = [1,2,3];

    n = 1;
    for i = 1:nFrames
        Event(n).tx = i;
        n = n+1;
    end

    for i = 1:nFrames
        Event(n).tx = nFrames - i + 1;
        n = n+1;
    end

end

function [Event,TX] = updateSequence(FocalPtMm)
    % Gen new TX and Events
    ScAT_Path = evalin('base',ScAT_Path);
    TTNB = evalin('base','TTNB');
    [TX, nFrames] = genTX(TTNB, FocalPtMm,ScAT_Path);
    Event = genEvent(nFrames);

    % Save updated TX back to base workspace
    assignin('base', 'TX', TX);
    assignin('base','Event',Event)

    % update&run
    Control(1).Command = 'update&Run';
    Control(1).Parameters = {'SeqControl'};
    
    Control(2).Command = 'update&Run';
    Control(2).Parameters = {'TX'};
    
    Control(3).Command = 'update&Run';
    Control(3).Parameters = {'Event'};
    
    assignin('base', 'Control', Control);

end


function [x, y] = lemniscatePoints(numberOfPoints, a)
% Generate a fixed number of approximately equally spaced points
% around a Bernoulli lemniscate.

    if numberOfPoints < 1 || numberOfPoints ~= round(numberOfPoints)
        error('numberOfPoints must be a positive integer.')
    end

    if a <= 0
        a = 1e-10;
    end

    % Densely sample the lemniscate
    t = linspace(0, 2*pi, 100001);

    xDense = a*cos(t) ./ (1 + sin(t).^2);
    yDense = a*sin(t).*cos(t) ./ (1 + sin(t).^2);

    % Calculate cumulative distance along the curve
    distance = [0, cumsum(hypot(diff(xDense), diff(yDense)))];

    % Specify equally spaced distances, excluding the repeated endpoint
    targets = linspace(0, distance(end), numberOfPoints + 1);
    targets(end) = [];

    % Interpolate coordinates at the target distances
    x = interp1(distance, xDense, targets);
    y = interp1(distance, yDense, targets);

end

function merged_points = merge_point_pairs_by_distance_v2(waypoints, dx_threshold)
%MERGE_POINT_PAIRS_BY_DISTANCE_V2 Merge globally closest waypoint pairs.
%
% At each step, the globally closest pair of unused points is selected.
% If their distance is less than or equal to dx_threshold, the pair is
% replaced by its centroid.
%
% Each point can be merged at most once per pass. Any remaining unpaired
% points are retained unchanged.
%
% Parameters
% ----------
% waypoints : n_points-by-n_dimensions array
%     Coordinates of the input waypoints.
%
% dx_threshold : scalar
%     Maximum Euclidean distance between two points for them to be merged.
%
% Returns
% -------
% merged_points : n_output_points-by-n_dimensions array
%     Waypoints after one merge pass.
%
% Raises
% ------
% Error
%     If waypoints is not two-dimensional or if dx_threshold is negative.

    points = double(waypoints);

    if ndims(points) ~= 2
        error('waypoints must have shape (n_points, n_dimensions).');
    end

    if dx_threshold < 0
        error('dx_threshold must be non-negative.');
    end

    n_points = size(points, 1);

    if n_points < 2
        merged_points = points;
        return;
    end

    % Calculate pairwise Euclidean distances.
    pair_distances = zeros(n_points);

    for i = 1:n_points
        diff = points - points(i, :);
        pair_distances(i, :) = sqrt(sum(diff.^2, 2))';
    end

    % Exclude self-distances and lower triangle.
    pair_distances(tril(true(n_points))) = inf;

    point_used = false(n_points, 1);
    merged_points = [];

    while true

        % Exclude pairs containing already-used points.
        available_distances = pair_distances;
        available_distances(point_used, :) = inf;
        available_distances(:, point_used) = inf;

        % Find globally closest available pair.
        [minimum_distance, linear_idx] = min(available_distances(:));

        if minimum_distance > dx_threshold || isinf(minimum_distance)
            break;
        end

        [point_a, point_b] = ind2sub( ...
            size(available_distances), linear_idx);

        centroid = (points(point_a, :) + points(point_b, :)) / 2;
        merged_points = [merged_points; centroid]; %#ok<AGROW>

        point_used(point_a) = true;
        point_used(point_b) = true;
    end

    % Retain unmerged points.
    merged_points = [merged_points; points(~point_used, :)];
end