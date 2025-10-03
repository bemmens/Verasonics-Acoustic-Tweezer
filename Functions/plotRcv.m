function plotRcv(ch,RcvData,Resource,Trans,Receive)
    wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
    chanels = 1:128;
    disp(wavelength)
    n_samples = Resource.RcvBuffer(1).rowsPerFrame;
    depth_axis = linspace(0,1,n_samples)*Receive.endDepth*wavelength*1e3;
    data = RcvData{1}(:,ch,1);

    disp(size(chanels))
    disp(size(depth_axis))
    disp(size(data))

    figure()
    plot(depth_axis,data)
    xlabel('Depth [mm]')

%     figure()
%     imagesc(RcvData{1}(:,:,1)); 
%     colormap('gray')
%     xlabel('Channel')


    % Compute analytic signal and envelope
    env = abs(hilbert(data));
    
    % Normalize and convert to dB (avoid log(0))
    env_norm = env ./ max(env(:));
    env_db = 20*log10(env_norm + eps);
    
    % Linear envelope plot (each channel)
    figure;
    plot(depth_axis, env);
    xlabel('Depth [mm]');
    ylabel('Amplitude');
    title('Envelope (linear)');

    % Crop region between 25 mm and 75 mm
    roiMask = depth_axis >= 25 & depth_axis <= 75;
    roi_init = depth_axis >=0 & depth_axis <= 25;

    depth_roi = depth_axis(roiMask);
    data_roi  = data(roiMask);
    env_roi   = env(roiMask);

    depth_roi_init = depth_axis(roi_init);
    data_roi_init  = data(roi_init);
    env_roi_init   = env(roi_init);

    % Plot linear envelope in ROI
    % figure;
    % plot(depth_roi, env_roi);
    % xlabel('Depth [mm]');
    % ylabel('Amplitude');
    % title('Envelope (25–75 mm)');

    % figure
    % plot(depth_roi_init, env_roi_init);
    % xlabel('Depth [mm]');
    % ylabel('Amplitude');
    % title('Envelope (0–25 mm)');

    % Find max envelope position in initial ROI (0–25 mm)
    if ~isempty(env_roi_init)
        [maxEnvInit, idxMaxInit] = max(env_roi_init);
        depthMaxInit = depth_roi_init(idxMaxInit);          % Depth in mm
        % Original sample index
        initSampleIndices = find(roi_init);
        origSampleIdx = initSampleIndices(idxMaxInit);

        % Mark on the existing initial ROI figure
        hold on;
        plot(depthMaxInit, maxEnvInit, 'ro', 'MarkerFaceColor', 'r');
        text(depthMaxInit, maxEnvInit, sprintf('  max @ %.2f mm', depthMaxInit), ...
            'VerticalAlignment','bottom','Color','r');
    else
        warning('Initial ROI (0–25 mm) is empty.');
    end

    % Find max envelope position in main ROI (25–75 mm)
    if ~isempty(env_roi)
        [maxEnvMain, idxMaxMain] = max(env_roi);
        depthMaxMain = depth_roi(idxMaxMain); % Depth in mm
        mainSampleIndices = find(roiMask);
        origSampleIdxMain = mainSampleIndices(idxMaxMain);

        % Plot on a new figure (main ROI with marker)
        figure;
        plot(depth_roi, env_roi); hold on;
        plot(depthMaxMain, maxEnvMain, 'ro', 'MarkerFaceColor','r');
        xlabel('Depth [mm]');
        ylabel('Amplitude');
        title('Envelope (25–75 mm) with maximum');
        text(depthMaxMain, maxEnvMain, sprintf('  max @ %.2f mm', depthMaxMain), ...
            'VerticalAlignment','bottom','Color','r');

    else
        warning('Main ROI (25–75 mm) is empty.');
    end

depth_surface = depthMaxMain - depthMaxInit;
% Print depth difference between maxima in mm
fprintf('Surface distance: %.2fmm\n', depth_surface);

end 




    
    

