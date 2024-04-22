function leverData = getLeverData(data,sessions,times,leverOffset)

    dt = diff(times,1,2);

    for s = 1:length(sessions)
        cur_session = sessions(s);
        leverTimes = data(cur_session).leverOnTimes;
        valid_on = iswithin(leverTimes, times(s,:)' + [-1; 1]);
        leverData(s).onTimes = leverTimes(valid_on);

        leverOff = data(cur_session).leverOffTimes;
        off_start = find(leverOff - leverData(s).onTimes(1) > 0,1);
        valid_diff = off_start - find(valid_on,1);
        leverData(s).offTimes = leverOff(find(valid_on) + valid_diff);

        leverData(s).onTimes = (leverData(s).onTimes - times(s,1) + sum(dt(1:s-1)) + leverOffset*1000)/1000;
        leverData(s).offTimes = (leverData(s).offTimes - times(s,1) + sum(dt(1:s-1)) + leverOffset*1000)/1000;

        leverData(s).leverCh = data(cur_session).leverCh(valid_on);
    end