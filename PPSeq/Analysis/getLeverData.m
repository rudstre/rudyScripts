function leverData = getLeverData(data,sessions,times,leverOffset,fs_lever)

    if nargin < 5
        fs_lever = 1000;
    end

    dt = diff(times,1,2);

    for s = 1:length(sessions)
        cur_session = sessions(s);
        leverTimes = data(cur_session).leverOnTimes;
        valid_on = iswithin(leverTimes/fs_lever, times(s,:)' + [-1; 1]);
        leverData(s).onTimes = leverTimes(valid_on);

        leverOff = data(cur_session).leverOffTimes;
        off_start = find(leverOff - leverData(s).onTimes(1) > 0,1);
        valid_diff = off_start - find(valid_on,1);
        leverData(s).offTimes = leverOff(find(valid_on) + valid_diff);

        leverData(s).onTimes = (leverData(s).onTimes - times(s,1)*fs_lever + sum(dt(1:s-1)))/fs_lever + leverOffset;
        leverData(s).offTimes = (leverData(s).offTimes - times(s,1)*fs_lever + sum(dt(1:s-1)))/fs_lever + leverOffset;

        leverData(s).leverCh = data(cur_session).leverCh(valid_on);
        leverData.step = 'seconds';
    end