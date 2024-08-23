function epochs = findEpochsFromBinary(bin)

if size(bin,2) == 1
    bin = bin';
end

epochStarts = find(diff(bin) == 1) + 1;
epochEnds = find(diff(bin) == -1);

if bin(1)
    epochStarts = [1 epochStarts];
end
if bin(end)
    epochEnds = [epochEnds length(bin)];
end

epochs(:,1) = epochStarts;
epochs(:,2) = epochEnds;
