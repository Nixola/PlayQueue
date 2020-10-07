love.graphics.setBackgroundColor(2/16, 2/16, 2/16)

local roll = require "seq.pianoroll".new()
roll.x, roll.y = 64, 64

local instruments = require "instruments"

local panel = require "seq.panels"

local SR = 44100
local SL = 512
local SQ = love.audio.newQueueableSource(SR,16,1, 4) -- "Queue type"...
local SD = love.sound.newSoundData(SL,SR,16,1) -- Buffer

local thread = love.thread.newThread("thread.lua")
local channel = love.thread.newChannel()
local presets = love.thread.newChannel()
channel:push(SR)
channel:push(SL)

channel:push(SQ)
channel:push(SD)

local gui = require("gui.src"):new()
local guiElements = {}

local waveforms = {}
local effects = {}
for i, filename in ipairs(love.filesystem.getDirectoryItems("waves")) do
  waveforms[#waveforms + 1] = filename:match("^(.-)%.lua$")
end
for i, filename in ipairs(love.filesystem.getDirectoryItems("effects")) do
  effects[#effects + 1] = filename:match("^(.-)%.lua$")
end

panel:init(gui, waveforms, effects)

local bpm = 180
do
  local textLine = gui:add("textLine", 32, 16, 48, nil, "bpm", nil, bpm)
  textLine.callback = function(newBpm)
    bpm = newBpm
  end
  textLine.unfocusCallback = function(self)
    self.text = tostring(bpm)
  end
  textLine.validate = function(text)
    if not tonumber(text) then
      return false
    end
    return text:match("^%s*(.-)%s*$")
  end
  guiElements.bpm = textLine


end

love.keyboard.setKeyRepeat(true)

thread:start(channel, presets)

for name, preset in pairs(instruments) do
  for i, v in ipairs(preset) do
    v.effects = v.effects or {}
    presets:push{
      amplitude = v.amplitude;
      keyshift  = v.keyshift;
      waveform  = v.waveform;
      effects   = #v.effects;
    }
    for i, e in ipairs(v.effects) do
      presets:push(e)
    end
  end
  channel:push({action = "preset", name = name, voices = #preset})
end


love.update = function(dt)
  roll:update(dt)
  gui:update(dt)
end


love.draw = function()
  roll:draw()
  gui:draw()
end


love.keypressed = function(k, kk, isRepeat)
  local shift = love.keyboard.isDown("lshift", "rshift")
  if k == "space" then
    channel:push{action = "clear"}
    local n = roll:getNotes(bpm)
    SQ:pause()
    local settings = panel:getSettings()
    for i, note in ipairs(n) do
      channel:push{
        action = "start",
        --id = i,
        instrument = "saw",
        attack = settings.attack,
        decay = settings.decay,
        sustain = settings.sustain,
        release = settings.release,
        duration = note.duration,
        delay = note.delay,
        frequency = note.pitch,
        amplitude = 0.6,
        effects = {{type = "vibrato", 6, 1/6}, {type = "flanger"}},
      }
    end
    if shift then
      print("Recording...")
      channel:push{
        action = "record",
        stop = "auto"
      }
    end
    SQ:play()
    roll:play(bpm)
  elseif k == "escape" then
    channel:push{action = "clear"}
    roll:stop()
  elseif k == "up" and shift then
    bpm = bpm + 1
    print("BPM:", bpm)
  elseif k == "down" and shift then
    bpm = bpm - 1
    print("BPM:", bpm)
  end
  roll:keypressed(k, kk, isRepeat)
  gui:keypressed(k, kk, isRepeat)
end

love.keyreleased = function(k, kk)
  
end

love.textinput = function(char)
  gui:textinput(char)
end

love.mousepressed = function(x, y, b)
  local pitch = roll:mousepressed(x, y, b)
  if pitch then
    channel:push {
      action = "start",
      instrument = "minkQM",
      attack = 0.1,
      decay = 0.3,
      sustain = 0.8,
      release = 0.1,
      duration = 0,
      delay = 0,
      frequency = pitch,
      amplitude = 1,
      effects = {{type = "vibrato", 6, 1/6}, {type = "flanger"}},
    }
  end
  gui:mousepressed(x, y, b)
end

love.mousemoved = function(x, y, dx, dy)
  roll:mousemoved(x, y)
end

love.mousereleased = function(x, y, b)
  roll:mousereleased(x, y, b)
  gui:mousereleased(x, y, b)
end

love.wheelmoved = function(wx, wy)
  roll:wheelmoved(wx, wy)
  gui:wheelmoved(wx, wy)
end

love.resize = function(w, h)
  roll.width = w - roll.x - 256
  roll.height = h - roll.y - 64

  panel:resize(w, h)
end