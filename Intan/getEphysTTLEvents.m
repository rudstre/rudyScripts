function leverTimes = getEphysTTLEvents(dataPath, ephysFilename, leverChannels, heartbeatChannel, heartbeatDuration)
% Extracts and processes TTL event times from an ephys recording session.
%
% TTL times are recorded as the number of samples from the start of the
% ephys session. This function converts them into milliseconds from the
% session start and validates heartbeat events.
%
% OUTPUT:
%   leverTimes       - Time of lever events in ms from the beginning of the session
%   leverStates      - On/Off state for each lever event
%   leverChs         - Lever input channel identity for each event
%   heartbeatTimes   - Time of heartbeat events in ms from the session start
%   heartbeatStates  - On/Off state for heartbeat events
%   sessionStartTime - MATLAB datetime format for the start of the recording session
%   leverSamples     - Raw lever event timestamps (in samples)

% Default values for optional arguments
if nargin < 3, leverChannels = 1:3; end
if nargin < 4, heartbeatChannel = 4; end

% Ensure filename is a string
if isnumeric(ephysFilename)
    ephysFilename = num2str(ephysFilename);
end

ttlOffset = 3000; % Offset applied to all TTL timestamps

% Ensure TTLChanges directory exists
ttlPath = fullfile(dataPath, ephysFilename, 'TTLChanges');
if ~exist(ttlPath, 'dir')
    disp('No TTL changes calculated for this file!');
    return;
end

% Validate heartbeat channel
heartbeatFile = fullfile(ttlPath, sprintf('Ch_%d', heartbeatChannel - 1));
fid = fopen(heartbeatFile);
ttlHeartbeat = fread(fid, [1, 25], 'uint64=>uint64');
fclose(fid);

% Compute heartbeat intervals (in seconds)
heartbeatIntervals = double(diff(ttlHeartbeat)) * (100/3000) * (1/1000);
heartbeatIntervals(1:3) = []; % Ignore first few if they are unreliable

% Check if heartbeat intervals are within expected range
if ~all(heartbeatIntervals > heartbeatDuration - 0.1 & heartbeatIntervals < heartbeatDuration + 0.1)
    disp('Heartbeat timing does not match expected duration.');
end

% Load TTL events from all channels
ttlEvents = cell(1, 16);
for ch = 0:15
    ttlFile = fullfile(ttlPath, sprintf('Ch_%d', ch));
    if exist(ttlFile, 'file')
        fid = fopen(ttlFile);
        ttlEvents{ch + 1} = fread(fid, [1, inf], 'uint64=>uint64');
        fclose(fid);
    else
        ttlEvents{ch + 1} = [];
    end
end

% Convert TTL timestamps to milliseconds from session start
for ch = 0:15
    ttlEvents{ch + 1} = double(ttlEvents{ch + 1} - ttlOffset) * (100/3000);
end

% Concatenate and sort lever event times
allLeverEvents = [ttlEvents{leverChannels}];
allLeverEvents = sort(allLeverEvents);

leverTimes = allLeverEvents;
end
