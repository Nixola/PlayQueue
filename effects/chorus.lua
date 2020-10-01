return function(effects, waveforms)
  return {
    init = function(self, note, args)
      local depth = args[1] or 0.1
      local n1 = effects.flanger(effects, waveforms):init(note, {depth})[1]
      local n2 = effects.flanger(effects, waveforms):init(note, {-depth})[1]
      return {n1, n2}
    end,
    args = {
      {name = "depth", type = "number"},
    }
  }
end