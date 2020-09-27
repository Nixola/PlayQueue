return function(effects, waveforms)
  return {
    init = function(self, note, args) --don't even know if this will work
      local delay = args[1] or 0.100 --seconds, needs testing
      local amplitude = args[2] or 0.5 --needs testing
      local depth = args[3] or math.ceil(math.log(amplitude, delay))
      local t = {}
      for i = 1, depth do
        t[i] = table.clone(note)
        t[i].delay = delay * i
        t[i].amplitude = t[i].amplitude * amplitude ^ i
      end
      return t
    end
  }
end