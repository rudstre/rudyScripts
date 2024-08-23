% Running TTL events extraction
% this assumes that the TTLChanges folder is under fpath/A026/EphysFile

fpath = uigetdir;
EphysFile = '637181493672024509';
levers = 1:3;
heartbeat = 4;
heartbeatDuration = 7;

leverTimes = ...
    getEphysTTLEvents(fpath, EphysFile, levers, heartbeat, heartbeatDuration);