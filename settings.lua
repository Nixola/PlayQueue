local settings = {}
settings.list = {"attack", "decay", "sustain", "release", "duration", "chorus"}
settings.selected = 0
settings.keys = {up = true, down = true, left = true, right = true, delete = true, escape = true}
settings.defaults = {}

settings.keypressed = function(self, k)
  local ctrl = love.keyboard.isDown("lctrl", "rctrl")
  local shift = love.keyboard.isDown("lshift", "rshift")
  local alt = love.keyboard.isDown("lalt")
  if k == "escape" then
    self.selected = 0
  elseif k == "up" then
    self.selected = (self.selected - 2) % #self.list + 1
  elseif k == "down" then
    self.selected = self.selected % #self.list + 1
  end

  if self.selected == 0 then return end
  if k == "left" then
    self[self.list[self.selected]] = (self[self.list[self.selected]] or 0) - (shift and (ctrl and 1 or 0.1) or 0.01)
    if self[self.list[self.selected]] < 0 then
      self[self.list[self.selected]] = self.defaults[self.list[self.selected]]
    end
  elseif k == "right" then
    self[self.list[self.selected]] = (self[self.list[self.selected]] or 0) + (shift and (ctrl and 1 or 0.1) or 0.01)
  elseif k == "delete" then
    self[self.list[self.selected]] = self.defaults[self.list[self.selected]]
  end
end

settings.format = function(self)
  local t, ti = {}, 1
  for i, v in ipairs(self.list) do
    if i == self.selected then
      t[ti] = ">"
      ti = ti + 1
    end
    t[ti] = string.format("%s: %0.2fs\n", v, self[v] or 6/0)
    ti = ti + 1
  end
  return table.concat(t, "")
end


return settings