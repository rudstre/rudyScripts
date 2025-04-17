function res = minWithEmpty(vec)
if isempty(vec)
    res = inf;
else
    res = min(vec);
end