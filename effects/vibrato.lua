return function(effects, waveforms)
  return {
    init = nil, --explicitly nil as example
    continuous = function(self, state, args)
      local speed = args[1] or 6
      local depth = args[2] or 1/6
      local waveform = args[3] or "sine"
      local ratio = 2^(waveforms[waveform](speed, state.ttime) * depth / 12 )
      return {phaseShift = ratio}
    end,
    args = {
      {name = "speed", type = "number"},
      {name = "depth", type = "number"},
      {name = "wave", type = "wave"},
    }
  }
end