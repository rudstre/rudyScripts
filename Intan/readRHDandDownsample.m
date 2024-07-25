function [acc_pow, ephys_dec, dio] = readRHDandDownsample(filename, shift, chunkSize)
    % Read and process data from an RHD file, including downsampling ephys data
    %
    % Inputs:
    %   filename: Name of the RHD file to read
    %   shift: Starting point for reading data
    %   chunkSize: Size of the data chunk to read
    %
    % Outputs:
    %   acc_pow: Power of the accelerometer data in the 3-5 Hz range
    %   ephys_dec: Downsampled electrophysiological data
    %   dio: Digital input/output data

    % Extract current chunk of data from RHD file
    fid = fopen(filename);
    [ephys, acc, ~, ~, dio] = readRHD_oldFormat(fid, shift, chunkSize, 64);
    fclose(fid);

    % Calculate the norm of accelerometer data
    acc_norm = vecnorm(acc);

    % Bandpass filter accelerometer data
    fc_acc = [0.5 150]; % Frequency range in Hz
    fs_acc = size(acc, 2) / chunkSize * 30000; % Sampling frequency
    [b_acc, a_acc] = butter(2, fc_acc / (fs_acc / 2), 'bandpass'); % 2nd-order Butterworth filter
    acc_filt = filter(b_acc, a_acc, acc_norm);

    %% Extract 3-5Hz power of accelerometer data
    binsize = 1; % Bin size in seconds
    binsize_s = binsize * fs_acc; % Bin size in samples
    acc_pow = [];

    % Sliding window to calculate 3-5Hz power
    for w = 1:length(acc_norm)
        % Get indices for the current window
        idx_start = max(1, round(w - binsize_s / 2));
        idx_end = min(length(acc_norm), round(w + binsize_s / 2));

        % Calculate 3-5Hz power for the window at every bin size
        if mod(w, binsize_s) == binsize_s / 2 % Centered window
            [pwr, fr] = pmtm(acc_filt(idx_start:idx_end), 2, [], fs_acc);
            acc_pow = [acc_pow; [w / fs_acc, sum(pwr(iswithin(fr, 3, 5)))]];
        end
    end

    %% Downsample electrophysiological data by 100x
    ephys_dec = zeros(size(ephys, 1), ceil(size(ephys, 2) / 100)); % Preallocate for downsampled data
    for ele = 1:size(ephys, 1)
        tmp = ephys(ele, :);
        tmp = decimate(tmp, 5, 4);
        tmp = decimate(tmp, 5, 4);
        ephys_dec(ele, :) = decimate(tmp, 4, 4) * 1e6; % Convert to microvolts
    end
end
