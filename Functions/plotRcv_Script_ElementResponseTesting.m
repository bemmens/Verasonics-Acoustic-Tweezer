file = 'DIYMk2_Day4_1';

load(strcat(file,'.mat'))

out_fname = strcat(file,'.csv');


wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
chanels = squeeze(Trans.Connector);
nCH_TX = size(chanels,1);
n_samples = Resource.RcvBuffer(1).rowsPerFrame;
depth_axis = linspace(0,1,n_samples)*Receive.endDepth*wavelength*1e3;
all_ch = RcvData{1}(:,:,1);

sample_rate = Receive.decimSampleRate; % in MHz
time = 0:n_samples/(sample_rate*1e6);

record_length_s = time(end);
disp(record_length_s)

%% Sorting channels
nCh = 128;
Chanels_RX = 1:nCh;
Chanels_match = ismember(Chanels_RX,chanels);
Chanels_Missing = Chanels_RX(~Chanels_match);
Channels = [chanels',Chanels_Missing];

sorted_data = zeros(size(all_ch));
distance = zeros(1,nCh);
for i = 1:nCh
    ch = Channels(i);
    sorted_data(:,i) = all_ch(:,ch);
end

sorted_data = sorted_data(1:n_samples/8,:);
depth_axis = depth_axis(1:n_samples/8);
summed_data = sum(abs(sorted_data));
% summed_data_cropped = summed_data(:,1:121)/max(summed_data);
summed_data_cropped = summed_data(:,1:121);


max_data = max(abs(sorted_data));
max_data_cropped = max_data(:,1:121)/max(max_data);

figure()
plot(summed_data_cropped)
xlabel('Element')
ylabel('Relative Cumulative Displacement')

array_data = reshape(summed_data_cropped,11,11);

% Export array_data as a CSV file
% Ensure numeric type and desired orientation (rows as first dimension)
arr = double(array_data);

% Write with comma delimiter and precision
writematrix(arr, out_fname);
disp(['Saved CSV array to ', out_fname])
% 
% figure()
% pcolor(array_data)
% colorbar()
% title('Apodisation Map')
% 
% 
% 
% % Use Fourier Interpolation to smooth data
% interp_order = 10; % Interpolation factor
% acll_ch_intrp = interpft(sorted_data, interp_order*n_samples, 1);
% depth_axis = linspace(0,1,interp_order*n_samples)*Receive.endDepth*wavelength*1e3;
% sorted_data = acll_ch_intrp;
% 
% for i = 1:nCh
%     distance(i) = calDistance(sorted_data,depth_axis,i);
% end
% 
% % Compute mean distance omitting outliers (median/MAD method)
% validIdx = ~isoutlier(distance,'mean');
% clean_d = distance(validIdx);
% mean_distance = mean(clean_d);
% std_distance = std(clean_d);    
% 
% figure()
% tiledlayout(2,1)
% nexttile
% plot(depth_axis, sorted_data);
% xlabel('Depth [mm]')
% ylabel('Amplitude')
% title('Received Data')
% 
% nexttile
% imagesc(1:128, depth_axis, sorted_data);
% colormap('gray')
% ylabel('Depth [mm]')
% xlabel('Channel')
% title('Received Data')
% 
% disp(['Mean Distance To Surface: ', num2str(mean_distance, '%.1f'), ' ± ', num2str(std_distance, '%.2f'), ' mm'])

% in = input('Filename:','s');
% save(string(in)+'.mat')

function h = calDistance(sorted_data,depth_axis,ch)
    data = sorted_data(:,ch);

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



