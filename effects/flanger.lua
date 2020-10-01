return function(effects, waveforms)
  return {
    init = function(self, note, args)
      local depth = args[1] or 0.1
      local amplitude = args[2] or 1/5
      local t = {}
      t[1] = table.clone(note)
      t[1].amplitude = note.amplitude * amplitude
      t[1].frequency = t[1].frequency + depth
      return t
    end,
    args = {
      {name = "depth", type = "number"},
      {name = "amplitude", type = "number"},
    }
  }
end