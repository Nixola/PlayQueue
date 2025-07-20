local overtone = function(n)
  return math.log(n)/math.log(2^(1/12))
end
local delta = 1
return {
  sine = {
    {amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} }
  },

  flute = {
    {amplitude = 0.7, keyshift = 0,  waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} }, 
    {amplitude = 0.7, keyshift = 12, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} }
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

  square = {
    {amplitude = .6, keyshift = 0, waveform = "square", effects = {{type = "chorus", .1}}},
  },

  double = {
    {amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
    {amplitude = 1, keyshift = 0.005, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} }
  },

  minkQM = {
    {amplitude = 1, keyshift = 0, waveform = "minkQM", effects = {{type = "vibrato", 6, 1/8}, } },
  },

  minkQM1 = {
    {amplitude = 1, keyshift = 0, waveform = "minkQM"},
  },

  expow = {
    {amplitude = 1, keyshift = 0, waveform = "expow"},
  },

  strings = {
  	{amplitude = 0.8, keyshift = 0, waveform = "minkQM"},
  	{amplitude = 0.8, keyshift = 0, waveform = "expow"},
  },

  vibraphone = {
  	{amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = .02, keyshift = overtone(4) --[[ ±1?? ]], waveform = "sine", effects = {{type = "vibrato", 6, 1/9}} },
  	{amplitude = .01, keyshift = overtone(32/3) --[[41]], waveform = "sine", effects = {{type = "vibrato", 6, 1/9}} },
  },

  test = {
  	{amplitude = 1, keyshift = overtone(3), waveform = "sine"},
  	{amplitude = 1/2, keyshift = overtone(4), waveform = "sine"},
    {amplitude = 1/3, keyshift = overtone(5), waveform = "sine"}
  }
}
