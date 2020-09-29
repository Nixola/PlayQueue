return function(phase, frequency)
    if frequency < 768 then -- TODO magic number; related to sampling rate
        return (phase * frequency * 2) % 2 - 1
    end
    local result = 0
    local x = 0
    local n = math.ceil(SR / 2 / frequency)
    for i=1, n do
        x = math.sin(phase * i * frequency * 2 * math.pi)
        x = x / i -- amplitude dropoff
        result = result + x
    end
    return result * math.pi / 4
end