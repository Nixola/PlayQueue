return function(phase, frequency) -- code by Zorg. Thanks!
    if frequency < 384 then -- TODO magic number; related to sampling rate
      phase = phase % (1/frequency)
      return phase * frequency <= 0.5 and 1 or -1
    end
    local result = 0
    local x = 0
    local n = math.ceil(SR / 2 / frequency)
    for i=1, n, 2 do
        x = math.sin(phase * i * frequency * 2 * math.pi)
        x = x / i -- amplitude dropoff
        result = result + x
    end
    return result
end
