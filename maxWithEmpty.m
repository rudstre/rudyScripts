function res = maxWithEmpty(vec)
if isempty(vec)
    res = -inf;
else
    res = max(vec);
end

end