function d = distFromRange(p,r)

if ~isscalar(p)
    d = arrayfun(@(x) distFromRange(x,r), p);
    return
end

dif = p - r;

if dif(1) < 0 % below range
    d = dif(1);
elseif all(dif > 0) % above range
    d = dif(2);
else % in range
    d = 0;
end