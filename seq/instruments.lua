local overtone = function(n)
  return math.log(n)/math.log(2^(1/12))
end
local delta = 1
return {
  sine = {
    {amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} }
  },

  organ = {
    {amplitude = 0.4, keyshift = -12, waveform = "sine", effects = {{type = "vibrato", 3, 1/10}} },
    {amplitude = 0.4, keyshift = 0,   waveform = "sine", effects = {{type = "vibrato", 3, 1/10}} },
    {amplitude = 0.4, keyshift = 12,  waveform = "sine", effects = {{type = "vibrato", 3, 1/10}} },
    {amplitude = 0.4, keyshift = 24,  waveform = "sine", effects = {{type = "vibrato", 3, 1/10}} },
    --{amplitude = 0.3, keyshift = 36,  waveform = "sine", effects = {{type = "vibrato", 3, 1/10}} }
  },

  saw = {
    {amplitude = .6, keyshift = 0, waveform = "sawtooth", effects = {{type = "vibrato", 6, 1/6}, {type = "chorus", .1}}},
  },

  triangle = {
    {amplitude = .6, keyshift = 0, waveform = "triangle", effects = {{type = "vibrato", 6, 1/6}, {type = "chorus", .1}}},
  },

  square = {
    {amplitude = .6, keyshift = 0, waveform = "square", effects = {{type = "chorus", .1}}},
  },

  strings = {
  	{amplitude = 0.8, keyshift = 0, waveform = "minkQM"},
  	{amplitude = 0.8, keyshift = 0, waveform = "expow"},
  },

  vibraphone = {
    envelope = {attack = 0.001, decay = 0.5, sustain = 0.8, release = 0.6},
  	{amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = 1/2, keyshift = overtone(4) --[[ ±1?? ]], waveform = "sine", effects = {{type = "vibrato", 6, 1/9}} },
  	{amplitude = 1/3, keyshift = overtone(32/3) --[[41]], waveform = "sine", effects = {{type = "vibrato", 6, 1/9}} },
  },
}
