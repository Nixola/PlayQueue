local sq = {{amplitude = 0.5, keyshift = 0, waveform = "sine"}}
for i = 1, 31, 2 do
  sq[#sq+1] = {amplitude = 0.5/i, keyshift = math.log(i) / math.log(2^(1/12)), waveform = "sine"}
end

local saw = {{amplitude = 0.5, keyshift = 0, waveform = "sine"}}
for i = 1, 20 do
  saw[#saw+1] = {amplitude = (0.5/i) * (-1)^(i+1), keyshift = math.log(i) / math.log(2^(1/12)), waveform = "sine"}
end

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
  ---[[
  saw = {
    {amplitude = .6, keyshift = 0, waveform = "sawtooth", effects = {{type = "chorus", .1}}},
  },

  square = {
    {amplitude = 1, keyshift = 0, waveform = "square", effects = {{type = "chorus", .1}}},
  },
  --[=[
  --]]
  saw = saw,
  square = sq,
  --]=]

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

  cantor = {
    {amplitude = 1, keyshift = 0, waveform = "cantor"}
  },

  vibraphone = {
  	{amplitude = .02, keyshift = -5, waveform = "sine"},
  	{amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = .02, keyshift = 7, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = .09, keyshift = 12, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  },

  test = {
  	{amplitude = 0.8, keyshift = 0, waveform = "sine"},
  	{amplitude = 0.1, keyshift = 0, waveform = "square"},
  }
}