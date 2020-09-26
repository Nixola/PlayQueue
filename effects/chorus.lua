return function(effects, waveforms)
  return {
    init = function(self, note, shift)
      shift = shift or 0.1
      local n1 = effects.flanger.init(note, shift)[1]
      note.amplitude = note.amplitude * 2
      local n2 = effects.flanger.init(note, -shift)[1]
      return {n1, n2}
    end
  }
end