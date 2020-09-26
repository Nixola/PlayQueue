return function(effects, waveforms)
  return {
    init = function(self, note, shift)
      shift = shift or 0.1
      local n1 = effects.flanger(effects, waveforms):init(note, shift)[1]
      local n2 = effects.flanger(effects, waveforms):init(note, -shift)[1]
      return {n1, n2}
    end
  }
end