local note = {}
local mt = {__index = note}

note.new = function(x, y, scale)
  local self = setmetatable({}, mt)
  self.x = x
  self.y = y
  self.length = 0
  self.scale = scale
  return self
end

note.finalize = function(self, x2)
  self.length = math.round((x2/self.scale.x - self.x) / self.scale.snap) * self.scale.snap
  self.length = math.max(0, self.length)
  if self.length == 0 then
    return false
  end
  return true
end

note.clone = function(self, offset)
  local n = self.new(self.x - offset, self.y, self.scale)
  n.length = self.length
  return n
end

note.drawStart = function(self)
  love.graphics.rectangle("fill", self.x * self.scale.x, self.y * self.scale.y + 1, 2, self.scale.y - 2)
end

note.drawEnd = function(self)
  love.graphics.rectangle("fill", (self.x + self.length) * self.scale.x - 2, self.y * self.scale.y + 1, 2, self.scale.y - 2)
end

note.drawMid = function(self)
  love.graphics.rectangle("fill", self.x * self.scale.x, self.y * self.scale.y + 1, self.length * self.scale.x, self.scale.y - 2)
end

return note