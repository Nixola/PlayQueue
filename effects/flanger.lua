return function(effects, waveforms)
  return {
    init = function(self, note, args)
      local shift = args[1] or 0.1
      local depth = args[2] or 1/5
      local t = {}
      t[1] = table.clone(note)
      t[1].amplitude = note.amplitude * depth
      t[1].frequency = t[1].frequency + shift
      return t
    end
  }
end