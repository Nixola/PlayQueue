local ceil, sin, pi, pi2 = math.ceil, math.sin, math.pi, math.pi^2
local SR = SR

return function(phase, frequency)
--    if frequency < 768 then -- TODO magic number; related to sampling rate
--        return (phase * frequency * 2) % 2 - 1
--    end
    local result = 0
    local x = 0
    local n = ceil(SR * 0.25 / frequency)
    local negative = false
    for i=1, n do
        local n = (i*2) - 1
        x = sin(phase * n * frequency * 2 * pi)
        x = x / n / n -- amplitude dropoff
        result = negative and (result - x) or (result + x)
        negative = not negative
    end
    return result * 8 / pi2
end
