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
    {amplitude = .6, keyshift = 0, waveform = "sawtooth", effects = {{type = "chorus", .1}}},
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
  	{amplitude = .02, keyshift = -5, waveform = "sine"},
  	{amplitude = 1, keyshift = 0, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = .02, keyshift = 7, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  	{amplitude = .09, keyshift = 12, waveform = "sine", effects = {{type = "vibrato", 6, 1/6}} },
  },

  test = {
  	{amplitude = 0.8, keyshift = 0, waveform = "sine"},
  	{amplitude = 0.8, keyshift = 0, waveform = "square", effects = {{type = "envelope", 0.02, 0.05, 0.1, 0.02}}},
  }
}