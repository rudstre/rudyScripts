function [dataVec, dataSerial] = decodeTeensy(filepath, baudRate, fs)
% decodeTeensy Decodes TTL-level UART data into structured packets and
% reconstructs a binary data vector.
%
%   [dataVec, dataSerial] = decodeTeensy(filepath, baud, fs)
%
% Inputs:
%   filepath - Path to the raw TTL-level waveform data.
%   baud     - UART baud rate.
%   fs       - Sampling frequency (default is 30000 Hz).
%
% Outputs:
%   dataVec    - Binary data vector (or matrix) with events marked.
%   dataSerial - Structure containing detailed packet information and settings.


% Input checking
if nargin < 3
    fs = 30000;
end

if nargin < 2
    baudRate = 3000;
end

if nargin < 1
    filepath = fileSelector('Select path to binary file');
end

% Step 0: Load binary data
fid = fopen(filepath, 'rb');
rawData = fread(fid, inf, 'uint16');
fclose(fid);

% Step 1: Convert the TTL waveform into a stream of UART bytes.
[byteStream, byteTimes] = decodeUARTfromTTL(rawData, fs, baudRate);

% Step 2: Decode the byte stream into packets.
packets = decodeSerialPackets(byteStream, byteTimes);

% Package serial information.
dataSerial.packets    = packets;
dataSerial.byteTimes  = byteTimes;
dataSerial.byteStream = byteStream;
dataSerial.fs         = fs;
dataSerial.baudRate   = baudRate;

% Deserialize packet information into a data vector.
dataVec = deserializeTeensy(dataSerial);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [decodedBytes, byteTimes] = decodeUARTfromTTL(binaryData, fs, baudRate)
% decodeUARTfromTTL Decodes UART bytes from a TTL waveform.
%
%   [decodedBytes, byteTimes] = decodeUARTfromTTL(binaryData, fs, baudRate)
%
% This function detects falling edges to locate start bits, verifies the
% start and stop bits, extracts 8 data bits (sampling at their midpoints),
% and reverses the bit order (to account for LSB-first transmission).
%
% Inputs:
%   binaryData - Binary waveform data (logical or thresholded numeric vector).
%   fs         - Sampling frequency.
%   baudRate   - UART baud rate.
%
% Outputs:
%   decodedBytes - Vector of decoded UART bytes.
%   byteTimes    - Vector of sample indices corresponding to each decoded byte.

bitSamples = fs / baudRate;  % Samples per bit period
decodedBytes = [];           % Initialize decoded bytes vector
byteTimes = [];              % Initialize byte timing vector

% Detect falling edges (potential start bits)
startBitQueue = find(diff(binaryData) == -1);

while ~isempty(startBitQueue)
    idx = startBitQueue(1);

    % Ensure there are enough samples for a full UART frame:
    % 1 start bit + 8 data bits + 1 stop bit = 10 bit periods.
    if idx + 10 * bitSamples > length(binaryData)
        break;
    end

    % Sample the start bit (should be low) at its center.
    startIdx = idx + 1;
    startBitSampleIdx = round(startIdx + 0.5 * bitSamples);
    startBitSample = binaryData(startBitSampleIdx);

    % Sample the stop bit (should be high) at its center.
    stopBitSampleIdx = round(startIdx + 9.5 * bitSamples);
    stopBitSample = binaryData(stopBitSampleIdx);

    % If the frame is invalid, remove this candidate and continue.
    if startBitSample ~= 0 || stopBitSample ~= 1
        startBitQueue(1) = [];
        continue;
    end

    % Extract all 8 data bits.
    dataBitStart = startBitSampleIdx + bitSamples;
    dataBitEnd   = stopBitSampleIdx - bitSamples;
    bits = binaryData(dataBitStart:bitSamples:dataBitEnd)';

    % Convert bit vector to a byte (little-endian).
    byte = bin2dec(char('0' + fliplr(bits)));
    decodedBytes = [decodedBytes, byte];  %#ok<AGROW>
    byteTimes(end+1) = startIdx;

    % Remove all candidate start bits within this frame.
    startBitQueue(startBitQueue <= stopBitSampleIdx) = [];
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function packets = decodeSerialPackets(byteVec, byteTimes)
% decodeSerialPackets Groups a stream of UART bytes into structured packets.
%
%   packets = decodeSerialPackets(byteVec, byteTimes)
%
% This function assumes that each packet is 11 bytes long and begins with a
% start marker (0xAA). It extracts the channel ID, pulse width, wait time,
% and verifies the checksum.
%
% Inputs:
%   byteVec   - Vector of UART bytes.
%   byteTimes - Vector of corresponding sample indices when each byte was detected.
%
% Output:
%   packets - Array of packet structures.

packetLen = 11;  % Fixed packet length (bytes)
packets = [];
i = 1;

while i <= (length(byteVec) - packetLen + 1)
    if byteVec(i) == hex2dec('AA')  % Start marker detected
        pktBytes = byteVec(i:i+packetLen-1);
        channelID = pktBytes(2);
        pulseWidth = typecast(uint8(pktBytes(3:6)), 'uint32');
        waitTime = typecast(uint8(pktBytes(7:10)), 'uint32');
        checksum = pktBytes(11);

        % Calculate expected checksum (modulo 256).
        expectedChecksum = mod(sum(pktBytes(2:6)), 256);
        valid = (checksum == expectedChecksum);

        % Store packet data in a structure.
        pktStruct = struct('startMarker', pktBytes(1), ...
            'channelID', channelID, ...
            'detectionTime', byteTimes(i), ...
            'waitTime', milliseconds(double(waitTime)/1000), ...
            'pulseWidth', milliseconds(double(pulseWidth)/1000), ...
            'valid', valid);
        packets = [packets; pktStruct];  %#ok<AGROW>
        i = i + packetLen;
    else
        i = i + 1;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dataVec = deserializeTeensy(dataSerial)
% deserializeTeensy Reconstructs a binary data vector from packet information.
%
%   dataVec = deserializeTeensy(dataSerial)
%
% For each packet, this function uses the detection time, wait time, and pulse
% width to compute the correct index in the output vector (or matrix) where
% an event is marked.
%
% Inputs:
%   dataSerial - Structure containing:
%                .packets: Array of packet structures.
%                .byteTimes: Vector of sample times.
%                .fs: Sampling frequency.
%                .baudRate: UART baud rate.
%
% Output:
%   dataVec - A binary data vector (or matrix) with events marked.

% Constant delay factor to account for packet preparation
cf = milliseconds(0.36);

fs = dataSerial.fs;
packets = dataSerial.packets;
dataVec = [];

for i = 1:length(packets)
    event = packets(i);
    eventCh = event.channelID;
    % Compute the start index using the detection time, wait time, and constant delay.
    eventStart = event.detectionTime - round(seconds(event.waitTime + cf) * fs);
    eventEnd   = eventStart + round(seconds(event.pulseWidth) * fs);

    if eventEnd < 1
        continue;
    end

    eventStart = max(eventStart, 1);

    % Expand dataVec if necessary.
    if length(dataVec) < eventEnd
        dataVec(eventEnd, eventCh) = 0;
    end

    % Mark the event for the corresponding channel.
    dataVec(eventStart:eventEnd, eventCh) = 1;
end
end
