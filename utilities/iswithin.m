function out = iswithin(in,a,b,strict)

if nargin < 4
    strict = false;
end
if nargin == 2 && ~isscalar(a)
    b = a(2,:);
    a = a(1,:);
end

if strict
    out = in > a & in < b;
else
    out = in >= a & in <= b;
end