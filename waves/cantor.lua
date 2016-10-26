local function baseConvert(x,b)
  local int, frac = math.floor(x), x % 1.0
  local i, d

  i,d = 1,{}
  while int > 0 do
    d[i] = int % b
    int = math.floor(int / b)
    i = i + 1
  end
  int = table.concat(d,''):reverse()
  int = int ~= '' and int or '0'

  i,d = 1,{}
  while frac > 0 do
    frac = frac * b
    d[i] = math.floor(frac)
    frac = frac - math.floor(frac)
    -- This should mean that depending on base, we want as many digits that
    -- would be "equivalent" to 17 significant places in base 10...
    -- but instead of 17, a multiplier of 24 is needed at least...
    if #d > 17*(math.log(10)/math.log(b)) then break end
    i = i + 1
  end
  frac = table.concat(d,'')
  frac = frac ~= '' and frac or '0'
  return int..frac
end

local function cantor(x) -- x: [0,1] -> [0,1]
  local s = baseConvert(x,3):sub(3) -- only works if number is 0.xxxxx...
  local t = {}
  local one = false
  for c in s:gmatch"." do
    if not one then
      if c == '1' then
        t[#t+1] = 1
        one = true
      elseif c == '2' then
        t[#t+1] = 1
      else
        t[#t+1] = 0
      end
    else
      t[#t+1] = 0
    end 
  end
  local sum = 0
  for i = #t, 1, -1 do
    sum = sum + t[i] * 2^-i
  end
  return sum
end

return function(p, v) return cantor(((p*v) % 1) / 3.0) * 2.0 - 1.0 end