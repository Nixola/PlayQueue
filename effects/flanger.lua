return function(effects, waveforms)
  return {
    init = function(self, note, shift)
      shift = shift or 0.1
      local t = {}
      note.amplitude = note.amplitude / 2
      t[1] = table.clone(note)
      t[1].frequency = t[1].frequency + shift
      return t
    end
  }
end