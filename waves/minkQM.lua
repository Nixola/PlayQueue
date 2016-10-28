local function minkowskiQM(x)
  local p = math.floor(x)
  local q,r,s,m,n,d,y = 1, p + 1, 1, 0, 0, 1.0, p
  -- out of range: ?(x) =~ x
  if x < p or ((p < 0 and r > 0) or (p >= 0 and r <= 0)) then return x end
  while true do
    -- invariants: q*r-p*s==1 and p/q <= x and x < r/s
    d = d / 2
    -- reached max possible precision
    if y + d == y then break end
    m = p + r
    -- sum overflowed
    if ((m < 0 and p >= 0) or (m >= 0 and p < 0)) then break end
    n = q + s
    -- sum overflowed
    if n < 0 then break end
    if x < m / n then r = m; s = n else y = y + d; p = m; q = n end
  end
  -- final round-off
  return y + d
end

return function(x, frequency)
  local i = x * frequency
  return (minkowskiQM(i) - i) * 7 
end