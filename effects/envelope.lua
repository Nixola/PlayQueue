return function(effects, waveforms)
  return {
    init = function(self, note)
      self.time = 0
      self.state = "delay"
      self.a = 0
      return {}
    end,

    continuous = function(self, note, args)
      local attack = args[1]
      local decay = args[2]
      local sustain = args[3]
      local release = args[4]
      --[[
      if self.state == "delay" then
        self.a = 0
        if note.time > note.delay then
          self.time = self.time - note.delay
          self.state = "attack"
        end
      end

      if self.state == "attack" then
        self.a = note.time / attack
        if self.time > attack then
          self.time = self.time - attack
          self.state = "decay"
        end
      end

      if self.state == "decay" then
        local tt = self.time / decay
        self.a = 1 * (1-tt) + sustain * tt
        if self.time > decay then
          self.time = self.time - decay
          self.state = "sustain"
        end
      end

      if self.state == "sustain" then
        self.a = sustain
      end

      if note.state == "release" then
        if self.state ~= "release" then
          self.state = release
          self.time = 0
          if self.state ~= "sustain" then
            self.sustain = self.a
          end
        end
        local tt = self.time / release
        self.a = (self.sustain or sustain) * (1-tt)
      end

      self.time = self.time + 1 / SR
      return {amplitude = self.a}
    end--]]
      if note.state == "release" then
        if note.time > release then
          note.state = "end"
          return
        end
        state = "release"
        time = note.time
        return {amplitude = sustain * (1 - time/release)}
      end

      local state, time
      if note.ttime <= note.delay then
        state = "delay"
        return
      elseif note.ttime <= note.delay + attack then
        state = "attack"
        time = note.ttime - note.delay
        return {amplitude = time / attack}
      elseif note.ttime <= note.delay + attack + decay then
        state = "decay"
        time = note.ttime - note.delay - attack
        return {amplitude = (1 - time) + sustain * time}
      else
        return {amplitude = sustain}
      end
    end
  },

  args = {
    {name = "attack", type = "number"},
    {name = "decay", type = "number"},
    {name = "sustain", type = "number"},
    {name = "release", type = "number"},
  }
end