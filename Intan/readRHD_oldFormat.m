function [ephys, acc, vdd, tmp, dio] = readRHD_oldFormat(fid, sampOffset, chunkSize, nelectrodes)

if nargin < 4
    nelectrodes = 64;
end

wordsPerSample = 88;

foffset = floor(sampOffset/60)*60 * wordsPerSample * 2;
chunkSize = floor(chunkSize/60)*60;

if sampOffset ~= -1
    fseek(fid, foffset, 'bof');
end

dat = fread(fid, chunkSize*wordsPerSample, 'uint16');

ephys = zeros(nelectrodes, chunkSize);
acc = zeros(3, chunkSize/4);
vdd = zeros(2, chunkSize/60);
tmp = zeros(2, chunkSize/60);

for n = 1 : nelectrodes
   ephys(n,:) = dat(12+n : wordsPerSample : chunkSize*wordsPerSample);
end

ephys = (ephys([(1:2:nelectrodes) (2:2:nelectrodes)], :) - 32768) * 1.95e-7;

dio = cast(dat(wordsPerSample-1:wordsPerSample:chunkSize*wordsPerSample), 'uint16');

for n = 1 : 3
   acc(n,:) = dat(n*wordsPerSample+10 : wordsPerSample*4 : chunkSize*wordsPerSample);
end
acc = (acc - 32768)*3.74e-5;

vdd(1,:) = dat(28*wordsPerSample+8+1 : 60*wordsPerSample : chunkSize*wordsPerSample);
vdd(2,:) = dat(28*wordsPerSample+8+2 : 60*wordsPerSample : chunkSize*wordsPerSample);
vdd = vdd * 7.48e-5;

tmp(1,:) = dat(20*wordsPerSample+8+1 : 60*wordsPerSample : chunkSize*wordsPerSample) - dat(12*wordsPerSample+8+1 : 60*wordsPerSample : chunkSize*wordsPerSample);
tmp(2,:) = dat(20*wordsPerSample+8+2 : 60*wordsPerSample : chunkSize*wordsPerSample) - dat(12*wordsPerSample+8+2 : 60*wordsPerSample : chunkSize*wordsPerSample);
tmp = (tmp/98.9)-273.15;