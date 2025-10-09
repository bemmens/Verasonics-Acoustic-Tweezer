function plotRcvV3(RcvData,Resource,Trans,Receive,TX)
    wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
    chanels = Trans.Connector';
    n_samples = Resource.RcvBuffer(1).rowsPerFrame;
    depth_axis = linspace(0,1,n_samples)*Receive.endDepth*wavelength*1e3;
    all_ch = RcvData{1}(:,:,1);

    %% Sorting channels
    sorted_data = zeros(size(all_ch));
    for i = 1:121
        ch = chanels(i);
        sorted_data(i,:) = all_ch(ch,:);
    end

    
    % % Use Fourier Interpolation to smooth data
    % interp_order = 4; % Interpolation factor
    % acll_ch_intrp = interpft(all_ch, interp_order*n_samples, 1);
    % depth_axis = linspace(0,1,interp_order*n_samples)*Receive.endDepth*wavelength*1e3;
    % all_ch = acll_ch_intrp;

    function h = calDistance(ch)
        data = sorted_data(ch,:);

        % Compute analytic signal and envelope
        env = abs(hilbert(data));
        
        roi_low = 25;
        roi_high = 75;

        roi_init_low = 0;
        roi_init_high = 25;

        function h = depthThreshold(low,high,env,threshold)
            roi = depth_axis >= low & depth_axis <= high;   
            depth_roi = depth_axis(roi);
            env_roi  = env(roi);
            threshold_mag = max(env_roi)*threshold;
            aboveThreshold = env_roi > threshold_mag;
            depthAboveThreshold = depth_roi(aboveThreshold);
            if isempty(depthAboveThreshold)
                h = 0; % No depth exceeded threshold
            else
                h = min(depthAboveThreshold); % First depth above threshold
            end
        end

        depthThresholdMain = depthThreshold(roi_low, roi_high, env, 0.5);
        depthThresholdInit = depthThreshold(roi_init_low, roi_init_high, env, 0.5);
        h_threshold = depthThresholdMain - depthThresholdInit;
        h = h_threshold; % You can choose to return h_max or h_threshold
    end

    distance = zeros(1,121);
    for i = 1:121
        distance(i) = calDistance(i);
    end

    % Compute mean distance omitting outliers (median/MAD method)
    validIdx = ~isoutlier(distance,'mean');
    clean_d = distance(validIdx);
    mean_distance = mean(clean_d);
    std_distance = std(clean_d);    

    figure()
    tiledlayout(3,1)
    nexttile
    plot(depth_axis, sorted_data);
    xlabel('Depth [mm]')
    ylabel('Amplitude')
    title('Received Data')

    nexttile
    imagesc( 1:121,depth_axis,sorted_data);
    colormap('gray')
    ylabel('Depth [mm]')
    xlabel('Channel')
    title('Received Data')

    nexttile
    scatter(1:121, distance,marker = '.')
    xlabel('Channel')
    ylabel('Distance [mm]')
    title(['Mean Distance To Surface: ', num2str(mean_distance, '%.2f'), ' ± ', num2str(std_distance, '%.2f'), ' mm'])


end