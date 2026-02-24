return function(phase, frequency)
--    if frequency < 768 then -- TODO magic number; related to sampling rate
--        return (phase * frequency * 2) % 2 - 1
--    end
    local result = 0
    local x = 0
    local n = math.ceil(SR / 2 / frequency)
    local negative = false
    for i=1, n do
        local n = (i*2) - 1
        x = math.sin(phase * n * frequency * 2 * math.pi)
        x = x / n / n -- amplitude dropoff
        result = negative and (result - x) or (result + x)
        negative = not negative
    end
    return result * 8 / math.pi / math.pi
end
