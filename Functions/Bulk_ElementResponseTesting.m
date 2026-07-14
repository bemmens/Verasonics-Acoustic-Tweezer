in_folder = '/Users/gv19838/Library/CloudStorage/OneDrive-UniversityofBristol/PhD/Vantage-4.8.4-2305101400/Verasonics-Acoustic-Tweezer BACKUP /RxData/';
out_folder = '/Users/gv19838/Library/CloudStorage/OneDrive-UniversityofBristol/PhD/Code/PythonRxData/';

files = dir(fullfile(in_folder, '*.mat'));

for k = 1:length(files)
    file_name = files(k).name;
    [~, file, ~] = fileparts(file_name);
    
    load(fullfile(in_folder, file_name));

    out_fname = fullfile(out_folder, strcat(file, '.csv'));

    wavelength = Resource.Parameters.speedOfSound/(Trans.frequency*1e6); % in m
    chanels = squeeze(Trans.Connector);
    nCH_TX = size(chanels,1);
    n_samples = Resource.RcvBuffer(1).rowsPerFrame;
    depth_axis = linspace(0,1,n_samples)*Receive.endDepth*wavelength*1e3;
    all_ch = RcvData{1}(:,:,1);

    sample_rate = Receive.decimSampleRate; % in MHz
    time = linspace(0,1,n_samples)/(sample_rate*1e6);

    record_length_s = time(end);
    % disp(record_length_s)

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
    time = time(1:n_samples/8); % Add this line
    RMS = rms(abs(sorted_data));
    RMS_cropped = RMS(:,1:121);

    array_data = reshape(RMS_cropped,11,11);

    % Export array_data as a CSV file
    % Ensure numeric type and desired orientation (rows as first dimension)
    arr = double(array_data);


    % Write with comma delimiter and precision
    % writematrix(arr, out_fname);
    % disp(['Saved CSV array to ', out_fname])


    % % % Use Fourier Interpolation to smooth data
    interp_order = 10; % Interpolation factor
    acll_ch_intrp = interpft(sorted_data, interp_order*n_samples, 1);
    time = linspace(0,1,interp_order*n_samples)/(sample_rate*1e6);
    sorted_data = acll_ch_intrp;

    % Save time and sorted_data in a python readable format (.csv)
    out_csv_name = fullfile(out_folder, strcat(file, '.csv'));
    writematrix([time', sorted_data], out_csv_name);
    disp(['Saved processed data to ', out_csv_name]);

    % plot(time,sorted_data)

    

end