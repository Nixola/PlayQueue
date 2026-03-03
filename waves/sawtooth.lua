local ceil, sin, pi = math.ceil, math.sin, math.pi
local SR = SR
return function(phase, frequency)
    if frequency < 768 then -- TODO magic number; related to sampling rate
        return (phase * frequency * 2) % 2 - 1
    end
    local result = 0
    local x = 0
    local n = ceil(SR / 2 / frequency)
    for i=1, n do
        x = sin(phase * i * frequency * 2 * pi)
        x = x / i -- amplitude dropoff
        result = result + x
    end
    return result * pi * .25
end
