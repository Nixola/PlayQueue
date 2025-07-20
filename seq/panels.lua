local panels = {}

local padding = 32

local validateNumber = function(text)
  if not tonumber(text) then
    return false
  end
  return text:match("^%s*(.-)%s*$")
end

panels.init = function(self, gui, waveforms, effects)
  self.width = 256
  self.waveforms = waveforms
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
end


panels.getSettings = function(self)
  return {
    attack = tonumber(self.elements.attack.text),
    decay = tonumber(self.elements.decay.text),
    sustain = tonumber(self.elements.sustain.text),
    release = tonumber(self.elements.release.text),
  }
end


panels.resize = function(self, w, h)
  self.elements.attack.x = w - self.width + padding
  self.elements.decay.x = w - self.width + padding
  self.elements.sustain.x = w - self.width + padding
  self.elements.release.x = w - self.width + padding

  self.elements.attackLabel.x = w - self.width + padding * 1.5 + 48
  self.elements.decayLabel.x = w - self.width + padding * 1.5 + 48
  self.elements.sustainLabel.x = w - self.width + padding * 1.5 + 48
  self.elements.releaseLabel.x = w - self.width + padding * 1.5 + 48
end

return panels
