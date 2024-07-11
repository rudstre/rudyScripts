function leverData = getLeverData(data,times,fs_lever)

    if nargin < 3
        fs_lever = 1000;
    end
    
    sessionStarts = datetime([data.sessionStartTime],'ConvertFrom','posix');
    
    for s = 1:size(times,1)
        cur_session = find(iswithin(sessionStarts, times(s,1) - hours(1), times(s,2)));
        cur_start = sessionStarts(cur_session);
        cur_data = data(cur_session);
        
        leverOnDates = cur_start + seconds(cur_data.leverOnTimes / fs_lever);
        leverOffDates = cur_start + seconds(cur_data.leverOffTimes / fs_lever);

        validOn = iswithin(leverOnDates, times(s,:)' + seconds([-1; 1]));
        validLeverOn = leverOnDates(validOn);
        firstLeverOff = find(leverOffDates > validLeverOn(1), 1);
        onOffOffset = firstLeverOff - find(validOn,1);
        validLeverOff = leverOffDates(find(validOn) + onOffOffset);
        
        leverOnSeconds = seconds(validLeverOn - times(s,1)); % change it to whatever unit
        leverOffSeconds = seconds(validLeverOff - times(s,1));

        leverData(s).onTimes = leverOnSeconds;
        leverData(s).offTimes = leverOffSeconds;
        leverData(s).session = cur_session;
        leverData(s).startTime = cur_start;
        leverData(s).leverCh = cur_data.leverCh(validOn);
        leverData(s).unit = 'seconds';
    end
    