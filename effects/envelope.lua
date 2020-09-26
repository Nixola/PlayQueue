return function(effects, waveforms)
  return {
    init = function(self, note)
      self.time = 0
      self.state = "delay"
      self.a = 0
      return {}
    end,

    continuous = function(self, note, attack, decay, sustain, release)
      if self.state == "delay" then
        self.a = 0
        if self.time > note.delay then
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
    end

  }
end