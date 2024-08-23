function leverTimes = ...
    getEphysTTLEvents(fpath, EphysFile, levers, heartbeat, heartbeatDuration)
% TTL times are saved as # samples from the beginning of the ephys
% recording session. Each recording folder is named according to the MSDN
% time of the beginning of the recording session (=> offset).
% This function transforms TTL events times to ms from offset, and
% transforms the offset to matlab datetime format.
% An event time can then be extracted by just adding the event time in ms
% to the offset.
% E.g. - milliseconds(eventTime) + offset

% OUTPUT: 
% leverTimes:       Time of lever events in ms from the beginning of the
%                   recording session
% leverStates:      On/Off state for each lever event
% leverChs:         Identity of lever input channel for each event
% heartbeatTimes:   Time of heartbeat events in ms from the beginning of
%                   the recording session
% heartbeatStates:  On/Off state for heartbeat events
% offset:           matlab datetime format for the beginning of the
%                   recording session.
% leverSamples:     


if nargin < 3
    levers=1:3;
end
if nargin < 4
    heartbeat = 4;
end

if isnumeric(EphysFile)
    EphysFile = num2str(EphysFile);
end

ttl_offset = 3000;

%%

if ~exist(fullfile(fpath, EphysFile, 'TTLChanges'))
    disp(['No TTL changes calculated for this file!!']);
end

% check to make sure heartbeat is there, if not throw error
fid = fopen(fullfile(fpath, EphysFile, 'TTLChanges', ['Ch_' num2str(heartbeat-1)]));
ttl_heartbeat = fread(fid, [1,25], 'uint64=>uint64');
fclose(fid);
time_heartbeat = double(diff(ttl_heartbeat)) * (100/3000) * (1/1000); % in seconds
time_heartbeat(1:3) = []; % ok if the first one is weird
if ~all(time_heartbeat > heartbeatDuration - 0.1 & time_heartbeat < heartbeatDuration + 0.1)
    disp('here')
end

% load TTLchanges
ttl_chs = {};
for ch = 0:15  % might as well load everything
    if exist(fullfile(fpath, EphysFile, 'TTLChanges', ['Ch_' num2str(ch)]))
    fid = fopen(fullfile(fpath, EphysFile, 'TTLChanges', ['Ch_' num2str(ch)]));
    ttl_chs{ch+1} = fread(fid,[1,inf],'uint64=>uint64');
    fclose(fid);
    else
        ttl_chs{ch+1} = [];
    end
end

% convert ttl to ms from start of file
for ch = 0:15
    ttl_chs{ch+1} = double(ttl_chs{ch+1} - ttl_offset) * (100/3000); % in ms!!
end

% concatenate lever taps
leverEventsAll = [ttl_chs{levers} ];
[~,idx] = sort(leverEventsAll);
leverEventsAll = leverEventsAll(idx);

% concatenate heartbeat
leverTimes = leverEventsAll;

end