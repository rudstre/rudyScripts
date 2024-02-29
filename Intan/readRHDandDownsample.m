function [acc_pow,ephys_dec,dio] = readRHDandDownsample(filename,shift,chunkSize)

    % extract current chunk of data
    fid = fopen(filename);
    [ephys, acc, ~, ~, dio] = readRHD_oldFormat(fid, shift, chunkSize, 64);
    fclose(fid);

    % take the norm of accelerometer data
    acc_norm = vecnorm(acc);

    % bandpass filter accelerometer data
    fc_acc = [.5 150];
    fs_acc = size(acc,2) / chunkSize * 30000;
    [b_acc, a_acc] = butter(2, fc_acc / (fs_acc / 2), 'bandpass'); % 4th order
    acc_filt = filter(b_acc ,a_acc, acc_norm);

    %% extract 3-5Hz power of accelerometer data
    binsize = 1;
    binsize_s = binsize * fs_acc;
    acc_pow = [];
    
    % sliding window to calculate 3-5Hz power
    for w = 1 : length(acc_norm)
        
        % Get indices for current window
        idx_start = w - binsize_s / 2 + 1;
        idx_end = w + binsize_s / 2;
        
        % Get 3-5Hz power for window every binsize
        if mod(w, binsize_s) == binsize_s / 2 % centered
            [pwr,fr] = pmtm(acc_filt(idx_start : idx_end), 2, [], fs_acc);
            acc_pow = [acc_pow; [w / fs_acc, sum(pwr(iswithin(fr, 3, 5)))]];
        end
    end

    %% downsample ephys data by 100x
    for ele = 1:size(ephys,1)
        tmp = ephys(ele,:);
        tmp = decimate(tmp,5,4);
        tmp = decimate(tmp,5,4);
        ephys_dec(ele,:) = decimate(tmp,4,4)*1e6; % convert to uV
    end
