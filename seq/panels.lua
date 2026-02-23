local panels = {}

local padding = 32

local validateNumber = function(text)
  if not tonumber(text) then
    return false
  end
  return text:match("^%s*(.-)%s*$")
end

panels.init = function(self, gui, instruments, effects)
  self.width = 256
  self.instruments = instruments
  self.effects = effects

  local screenWidth = love.graphics.getWidth()
  local baseX = screenWidth - self.width
  self.gui = gui

  self.elements = {}

  self.elements.attack = gui:add("textLine", baseX + padding, padding, 48, nil, "attack", nil, 0.05)
  self.elements.attack.validate = validateNumber
  self.elements.attackLabel = gui:add("text", baseX + padding * 1.5 + 48, padding, "Attack", {})

  self.elements.decay = gui:add("textLine", baseX + padding, padding + padding, 48, nil, "decay", nil, 0.01)
  self.elements.decay.validate = validateNumber
  self.elements.decayLabel = gui:add("text", baseX + padding * 1.5 + 48, padding + padding, "Decay", {})

  self.elements.sustain = gui:add("textLine", baseX + padding, padding + 2*padding, 48, nil, "sustain", nil, 0.8)
  self.elements.sustain.validate = validateNumber
  self.elements.sustainLabel = gui:add("text", baseX + padding * 1.5 + 48, padding + 2*padding, "Sustain", {})

  self.elements.release = gui:add("textLine", baseX + padding, padding + 3*padding, 48, nil, "release", nil, 0.1)
  self.elements.release.validate = validateNumber
  self.elements.releaseLabel = gui:add("text", baseX + padding * 1.5 + 48, padding + 3*padding, "Release", {})

  self.elements.amplitude = gui:add("textLine", baseX + padding, padding + 4*padding, 48, nil, "amplitude", nil, 1)
  self.elements.amplitude.validate = validateNumber
  self.elements.amplitudeLabel = gui:add("text", baseX + padding * 1.5 + 40, padding + 4*padding, "Amplitude", {})

  self.elements.panL = gui:add("textLine", baseX + padding, padding + 5*padding, 48, nil, "panL", nil, 1)
  self.elements.panL.validate = validateNumber
  self.elements.panR = gui:add("textLine", baseX + padding * 1.5 + 32, padding + 5*padding, 48, nil, "panR", nil, 1)
  self.elements.panR.validate = validateNumber
  
  local k = {} for i, v in pairs(instruments) do k[#k+1] = i end
  table.sort(k)
  self.elements.instrument = gui:add("dropdown", baseX + padding, padding + 6*padding, k)
  self.elements.instrument.callback = function(i)
    local e = self.instruments[k[i]].envelope
    if e then
      for i, v in pairs(self.elements) do
        if e[i] then
          v.text = tostring(e[i])
        end
      end
    end
  end
end


panels.getSettings = function(self)
  return {
    attack = tonumber(self.elements.attack.text),
    decay = tonumber(self.elements.decay.text),
    sustain = tonumber(self.elements.sustain.text),
    release = tonumber(self.elements.release.text),
    amplitude = tonumber(self.elements.amplitude.text),
    instrument = self.elements.instrument.button.text,
    pan = {tonumber(self.elements.panL.text), tonumber(self.elements.panR.text)},
  }
end

panels.setSettings = function(self, settings)
  self.elements.attack.text     = tostring(settings.attack)
  self.elements.decay.text      = tostring(settings.decay)
  self.elements.sustain.text    = tostring(settings.sustain)
  self.elements.release.text    = tostring(settings.release)
  self.elements.amplitude.text  = tostring(settings.amplitude)
  self.elements.instrument.button.text = settings.instrument
  self.elements.panL.text = tostring(settings.pan[1])
  self.elements.panR.text = tostring(settings.pan[2])
end


panels.resize = function(self, w, h)
  local x, tx = w - self.width + padding, w - self.width + padding * 1.5 + 48
  self.elements.attack.x     = x
  self.elements.decay.x      = x
  self.elements.sustain.x    = x
  self.elements.release.x    = x
  self.elements.amplitude.x  = x
  self.elements.instrument.x = x
    self.elements.instrument.button.x = x
    self.elements.instrument.panel.x = x
  self.elements.panL.x = x
  self.elements.panR.x = tx

  self.elements.attackLabel.x    = tx
  self.elements.decayLabel.x     = tx
  self.elements.sustainLabel.x   = tx
  self.elements.releaseLabel.x   = tx
  self.elements.amplitudeLabel.x = tx
end

return panels
