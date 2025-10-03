function plotRcvV2(RcvData,Resource,Trans,Receive,TX)
    wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
    chanels = 1:128;
    n_samples = Resource.RcvBuffer(1).rowsPerFrame;
    depth_axis = linspace(0,1,n_samples)*Receive.endDepth*wavelength*1e3;
    samples_per_wavelength = n_samples/Receive.endDepth;
    all_ch = RcvData{1}(:,:,1);

    % delays_periods = TX.Delay;
    % delays_samples = round(delays_periods*samples_per_wavelength);
    % all_ch = circshift(all_ch, -delays_samples);

    function h = calDistance(ch)
        data = all_ch(:,ch);

        % Compute analytic signal and envelope
        env = abs(hilbert(data));
        
        roi_low = 25;
        roi_high = 75;

        roi_init_low = 0;
        roi_init_high = 25;

        function depthMax = findMax(low,high,env) 
            % low and high limits of roi in mm
            roi = depth_axis >= low & depth_axis <= high;   
            depth_roi = depth_axis(roi);
            env_roi  = env(roi);
            [max_value, idxMax] = max(env_roi);
            depthMax = depth_roi(idxMax);          % Depth in mm
        end

        depthMaxMain = findMax(roi_low, roi_high, env);
        depthMaxInit = findMax(roi_init_low, roi_init_high, env);
        h = depthMaxMain - depthMaxInit;
    end

    distance = zeros(1,128);
    for ch = chanels
        distance(ch) = calDistance(ch);
    end


    % Compute mean distance omitting outliers (median/MAD method)
    validIdx = ~isoutlier(distance,'mean');
    clean_d = distance(validIdx);
    mean_distance = mean(clean_d);
    std_distance = std(clean_d);    

    figure()
    tiledlayout(4,1)
    nexttile
    plot(depth_axis, all_ch);
    xlabel('Depth [mm]')
    ylabel('Amplitude')
    title('Received Data')

    nexttile
    imagesc(chanels, depth_axis, all_ch);
    colormap('gray')
    ylabel('Depth [mm]')
    xlabel('Channel')
    title('Received Data')

    nexttile
    scatter(chanels, distance,marker = '.')
    xlabel('Channel')
    ylabel('Distance [mm]')
    title(['Mean Distance To Surface: ', num2str(mean_distance, '%.2f'), ' ± ', num2str(std_distance, '%.2f'), ' mm'])


end