function [acc_pow,ephys_dec] = readRHDandDownsample(filename,shift,chunkSize)

    fid = fopen(filename);
    [ephys, acc, vdd, tmp, dio] = readRHD_oldFormat(fid, shift, chunkSize, 64);
    fclose(fid);

    acc_norm = vecnorm(acc);

    fc_acc = [.5 150];
    fs_acc = size(acc,2)/chunkSize*30000;
    [b_acc,a_acc] = butter(2,fc_acc/(fs_acc/2),'bandpass');

    acc_filt = filter(b_acc,a_acc,acc_norm);

    binsize = 1;
    binsize_s = binsize*fs_acc;
    acc_pow = [];
    for i = 1:length(acc_norm)
        if mod(i,binsize_s) == binsize_s/2 % centered
            [pmt,fr] = pmtm(acc_filt(i-binsize_s/2+1:i+binsize_s/2),2,binsize_s,fs_acc);
            acc_pow = [acc_pow; [i/fs_acc sum(pmt(iswithin(fr,3,5)))]];
        end
    end

    for i = 1:size(ephys,1)
        tmp = ephys(1,:); ephys(1,:) = [];
        tmp = decimate(tmp,5,4);
        tmp = decimate(tmp,5,4);
        ephys_dec(i,:) = decimate(tmp,4,4);
    end
