local Note = require "seq.note"

local roll = {}
local mt = {__index = roll}

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

math.round = function(x) return math.floor(x + .5) end

roll.new = function(min, max)
  local self = setmetatable({}, mt)
  self.min = min or 24
  self.max = max or 57
  self.x = 0
  self.y = 0
  self.width = 600
  self.height = 512
  self.scroll = {x = 0, y = 0, targetX = 0, targetY = 0}
  self.scale = {
    x = 2,     -- Pixels per 64th
    y = 24,    -- Pixels per row
    snap = 16, -- 64ths per snap
  }
  self.notes = {}

  self.creating = nil

  return self
end


roll.update = function(self, dt)
  self.scroll.x = (self.scroll.targetX + self.scroll.x) / 2
  self.scroll.y = (self.scroll.targetY + self.scroll.y) / 2
end


roll.draw = function(self)
  love.graphics.push()
    lg.translate(self.x, self.y)

    -- Vertical grid lines
    lg.setColor(5/16, 5/16, 5/16)
    lg.setLineWidth(1)
    local distance = self.scale.snap * self.scale.x
    for x = self.scroll.x % distance, self.width, self.scale.snap * self.scale.x do
      lg.line(x - .5, 0, x - .5, self.height)
    end

    -- Horizontal grid lines
    lg.setColor(3/16, 3/16, 3/16)
    lg.setLineWidth(2)
    for y = self.scroll.y % self.scale.y, self.height, self.scale.y do
      lg.line(0, y, self.width, y)
    end
    lg.setColor(6/16, 6/16, 6/16)
    lg.rectangle("line", 0, 0, self.width, self.height)
    lg.push()
      lg.translate(self.scroll.x, self.scroll.y)
      lg.setColor(0, 1, 0, 5/16)
      for i, note in ipairs(self.notes) do
        note:drawMid() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end

      lg.setColor(6/16, 11/16, 6/16)
      for i, note in ipairs(self.notes) do
        note:drawStart() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end

      lg.setColor(11/16, 6/16, 6/16)
      for i, note in ipairs(self.notes) do
        note:drawEnd() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end
    lg.pop()

  lg.pop()
end


roll.keypressed = function(self, k, kk, isRepeat)
  if k == "up" then
    self.scale.snap = math.min(self.scale.snap * 2, 64)
  elseif k == "down" then
    self.scale.snap = math.max(self.scale.snap / 2, 1)
  end
end


roll.mousepressed = function(self, x, y, b)
  x = x - self.x - self.scroll.x
  y = y - self.y - self.scroll.y
  local shift = lk.isDown("lshift", "rshift")
  if b == 1 and shift then
    local nx = math.round(x / self.scale.x / self.scale.snap) * self.scale.snap
    local ny = math.floor(y / self.scale.y)
    local note = Note.new(nx, ny, self.scale)
    self.notes[#self.notes + 1] = note
    self.creating = note
  elseif b == 2 then
    for i = #self.notes, 1, -1 do
      local note = self.notes[i]
      local nx = note.x * self.scale.x
      local ny = note.y * self.scale.y
      local nw = note.length * self.scale.x
      local nh = self.scale.y
      if x >= nx and x <= nx + nw and y >= ny and y <= ny + nh then
        table.remove(self.notes, i)
        break
      end
    end
  end

end


roll.mousereleased = function(self, x, y, b)
  x = x - self.x - self.scroll.x
  y = y - self.y - self.scroll.y
  if b == 1 and self.creating then
    if not self.creating:finalize(x) then
      self.notes[#self.notes] = nil
    end
    self.creating = nil
  end
end


roll.mousemoved = function(self, x, y)
  x = x - self.x - self.scroll.x
  y = y - self.y - self.scroll.y
  if self.creating then
    self.creating:finalize(x)
  end
end


roll.getNotes = function(self, bpm)
  local beat = 60 / bpm
  local notes = {}
  for i, v in ipairs(self.notes) do
    local note = {}
    note.pitch = self.max - v.y + 1
    note.delay = v.x / 16 * beat
    note.duration = v.length / 16 * beat
    notes[i] = note
  end
  return notes
end


roll.wheelmoved = function(self, wx, wy)
  if lk.isDown("lshift", "rshift") then
    wx, wy = wy, wx
  end

  self.scroll.targetX = math.min(self.scroll.targetX + wx * self.scale.x * 16, 0) -- quarter; TODO magic number
  self.scroll.targetY = self.scroll.targetY + wy * self.scale.y * 3  -- TODO magic number
end

return roll