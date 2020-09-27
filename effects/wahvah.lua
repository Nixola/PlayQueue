return function(effects, waveforms)
  return {
    init = nil, --explicitly nil as example
    continuous = function(self, state, args)
      local speed = args[1] or 6
      local depth = args[2] or 1/6
      local waveform = args[3] or "sine"
      local amplitude = (waveforms[waveform](speed, state.ttime) * depth + 1) /2
      return {amplitude = amplitude}
    end
  }
end