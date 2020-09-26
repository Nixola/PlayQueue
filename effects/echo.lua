return function(effects, waveforms)
  return {
    init = function(self, note, delay, amount, depth) --don't even know if this will work
      delay = delay or 0.100 --seconds, needs testing
      amplitude = amplitude or 0.5 --needs testing
      depth = depth or math.ceil(math.log(amplitude, depth))
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