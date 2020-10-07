local Note = require "seq.note"

local roll = {}
local mt = {__index = roll}

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

math.round = function(x) return math.floor(x + .5) end

local blacks = {[1] = true, [3] = true, [6] = true, [8] = true, [10] = true}
local noteNames = {[0] = 
  {{name = "C%d"}, {name = "B#%d", octave = -1}, {name = "Dbb%d"}},
  {{name ="C#%d"}, {name ="Db%d"}},
  {{name ="D%d"}, {name ="C×%d"}, {name ="Ebb%d"}},
  {{name ="D#%d"}, {name ="Eb%d"}},
  {{name ="E%d"}, {name ="D×%d"}, {name ="Fb%d"}},
  {{name = "F%d"}, {name = "E#%d"}, {name = "Gbb%d"}},
  {{name = "F#%d"}, {name = "Gb%d"}},
  {{name = "G%d"}, {name = "F×%d"}, {name = "Abb%d"}},
  {{name = "G#%d"}, {name = "Ab%d"}},
  {{name = "A%d"}, {name = "G×%d"}, {name = "Bbb%d"}},
  {{name = "A#%d"}, {name = "Bb%d"}},
  {{name = "B%d"}, {name = "A×%d"}, {name = "Cb%d", octave = 1}}
}

roll.new = function(min, max)
  local self = setmetatable({}, mt)
  self.min = min or 36
  self.max = max or 84
  self.x = 0
  self.y = 0
  self.margin = 32
  self.width = 600
  self.height = 512
  self.scroll = {x = 0, y = 0, targetX = 0, targetY = 0}
  self.scale = {
    x = 32,     -- Pixels per quarter
    y = 24,    -- Pixels per row
    snap = 1,  -- quarters per snap
  }
  self.notes = {{}}
  self.set = 1

  self.creating = nil

  self.playing = false
  self.time = 0

  return self
end


roll.newSet = function(self)
  self.notes[#self.notes + 1] = {}
  self.set = #self.notes
  return self.set
end


roll.update = function(self, dt)
  -- TODO: proper smoothing
  self.scroll.x = (self.scroll.targetX + self.scroll.x) / 2
  self.scroll.y = (self.scroll.targetY + self.scroll.y) / 2

  -- Updating play timer
  if self.playing then
    self.time = self.time + dt
    -- TODO: scroll to playback head
    -- TODO: stop if all notes have ended
  end
end


roll.draw = function(self)
  love.graphics.push()
    lg.translate(self.x, self.y)
    lg.setScissor(self.x, self.y - self.margin, self.width, self.height + self.margin)
    -- Vertical grid lines
    lg.setColor(1/2, 1/2, 1/2, 8/16)
    lg.setLineWidth(1)
    for snapExp = math.log(self.scale.snap) / math.log(2), 2, 1 do
      local snap = 2^snapExp
      local distance = snap * self.scale.x
      for x = self.scroll.x % distance, self.width, snap * self.scale.x do
        lg.line(x - .5, 0, x - .5, self.height)
      end
    end

    lg.setColor(10/16, 10/16, 10/16)
    for x = math.round(self.scroll.x) % (self.scale.x * 4), self.width, self.scale.x * 4 do --mark beats
      local beat = math.round(x / self.scale.x / 4 - math.round((self.scroll.x) / self.scale.x / 4) ) + 1
      love.graphics.print(tostring(beat), x, -16)
    end
    --[[
    local distance = self.scale.snap * self.scale.x
    for x = self.scroll.x % distance, self.width, self.scale.snap * self.scale.x do
      lg.line(x - .5, 0, x - .5, self.height)
    end]]

    -- Horizontal grid lines
    lg.setScissor(self.x - self.margin, self.y, self.width + self.margin, self.height)
    lg.setLineWidth(2)
    local notRemainder = ((1+self.scroll.y) / self.scale.y ) * self.scale.y
    for y = self.scroll.y % self.scale.y - self.scale.y, self.height, self.scale.y do
      local pitch = self.max + math.floor( (notRemainder - y + 1) / self.scale.y )
      local octave = math.floor(pitch / 12) - 1
      local note = pitch%12

      lg.setColor(4/16, 4/16, 4/16)
      lg.line(0, y, self.width, y)
      if not blacks[note] then
        lg.setColor(1, 1, 1, 1/16)
        lg.rectangle("fill", 0, y, self.width, self.scale.y)
        lg.setColor(1, 1, 1, 4/16)
      else
        lg.setColor(0, 0, 0, 4/16)
      end
      lg.rectangle("fill", -self.margin, y + 1, self.margin - 1, self.scale.y - 2)
      lg.setColor(1, 1, 1, 4/16)
      lg.print(noteNames[note][1].name:format(math.floor(octave + (noteNames[note][1].octave or 0) )), -self.margin + 4, y + 4)
    end
    lg.setColor(6/16, 6/16, 6/16, 1)
    lg.rectangle("line", 0, 0, self.width, self.height)

    lg.setScissor(self.x, self.y, self.width, self.height)
    lg.push()
      lg.translate(self.scroll.x, self.scroll.y)
      lg.setColor(0, 1, 0, 6/16)
      for i, note in ipairs(self.notes[self.set]) do
        note:drawMid() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end

      lg.setColor(6/16, 11/16, 6/16)
      for i, note in ipairs(self.notes[self.set]) do
        note:drawStart() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end

      lg.setColor(2/16, 4/16, 2/16)
      for i, note in ipairs(self.notes[self.set]) do
        note:drawEnd() -- TODO: when adding/moving notes, collision between notes should be found and each note should have an index set so that a "strip" of it is drawn and acts as button for the note
      end

      if self.playing then
        lg.setColor(8/16, 8/16, 8/16)
        local x = self.time * self.scale.x * self.bpm / 60
        lg.line(x, 0, x, 1080) -- FIX THIS
      end
    lg.pop()
    lg.setScissor()

  lg.pop()
end


roll.keypressed = function(self, k, kk, isRepeat)
  local shift = lk.isDown("lshift", "rshift")
  if k == "down" and not shift then
    self.scale.snap = math.min(self.scale.snap * 2, 4)
  elseif k == "up" and not shift then
    self.scale.snap = math.max(self.scale.snap / 2, 1/8)
  end
end


roll.mousepressed = function(self, x, y, b)
  local uiX = x - self.x
  local uiY = y - self.y
  x = x - self.x - self.scroll.x
  y = y - self.y - self.scroll.y
  local shift = lk.isDown("lshift", "rshift")
  if b == 1 and shift and uiX >= 0 and uiX <= self.width then
    local nx = math.round(x / self.scale.x / self.scale.snap) * self.scale.snap
    local ny = math.floor(y / self.scale.y)
    local note = Note.new(nx, ny, self.scale)
    self.notes[self.set][#self.notes[self.set] + 1] = note
    self.creating = note
  elseif b == 2 then
    for i = #self.notes[self.set], 1, -1 do
      local note = self.notes[self.set][i]
      local nx = note.x * self.scale.x
      local ny = note.y * self.scale.y
      local nw = note.length * self.scale.x
      local nh = self.scale.y
      if x >= nx and x <= nx + nw and y >= ny and y <= ny + nh then
        table.remove(self.notes[self.set], i)
        break
      end
    end
  end

  if uiX < 0 and uiY >= 0 and uiY <= self.height then
    local pitch = self.max - math.floor(y / self.scale.y)
    local note = pitch % 12
    local noteName = noteNames[note]
    if shift then
      if b == 1 then
        table.insert(noteName, table.remove(noteName, 1))
      elseif b == 2 then
        table.insert(noteName, 1, table.remove(noteName, #noteName))
      end
    elseif b == 1 then
      return pitch
    end
  end

end


roll.mousereleased = function(self, x, y, b)
  x = x - self.x - self.scroll.x
  y = y - self.y - self.scroll.y
  if b == 1 and self.creating then
    if not self.creating:finalize(x) then
      self.notes[self.set][#self.notes[self.set]] = nil
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


roll.getNotes = function(self, bpm, set)
  local beat = 60 / bpm
  local notes = {}
  for set_i, v in ipairs(self.notes) do
    if (set_i == set) or (set == nil) then
      for i, vv in ipairs(v) do
        local note = {}
        note.pitch = self.max - vv.y
        print(note.pitch)
        note.delay = vv.x * beat
        note.duration = vv.length * beat
        note.set = set_i
        notes[#notes + 1] = note
      end
    end
  end
  return notes
end


roll.play = function(self, bpm)
  self.playing = true
  self.bpm = bpm
  self.time = 0
end


roll.stop = function(self)
  self.playing = false
end

roll.wheelmoved = function(self, wx, wy)
  if lk.isDown("lshift", "rshift") then
    wx, wy = wy, wx
  end
  if lk.isDown("lctrl", "rctrl") then
    self.scroll.x = self.scroll.x * self.scale.x
    self.scroll.y = self.scroll.y * self.scale.y
    self.scale.x = math.max(self.scale.x + wx, 8)
    self.scale.y = math.max(self.scale.y + wy, 8)
    self.scroll.x = self.scroll.x / self.scale.x
    self.scroll.y = self.scroll.y / self.scale.y
  else
    self.scroll.targetX = math.min(self.scroll.targetX + wx * self.width / 3, 0) -- TODO magic number
    self.scroll.targetY = math.max(math.min(self.scroll.targetY + wy * self.height / 6, 0), math.min(self.height - (self.max - self.min + 1) * self.scale.y, 0))  -- TODO magic number
  end
end

return roll