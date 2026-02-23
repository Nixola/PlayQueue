local utils = require "seq.utils"

love.graphics.setBackgroundColor(2/16, 2/16, 2/16)

local rolls = {}
for i = 1, 12 do
    rolls[i] = require "seq.pianoroll".new(i)
    local v = rolls[i]
    v.x, v.y = 64, 64
    v.scroll = rolls[1].scroll
    v.scale = rolls[1].scale
    v.playback = rolls[1].playback
end
local selectedRoll = 1
--local roll = require "seq.pianoroll".new()
local modes = require "seq.modes"

--roll.x, roll.y = 64, 64

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
local guiElements = {pianoRollButtons = {}}

local selectPianoRoll = function(n)
  local oldButton = guiElements.pianoRollButtons[selectedRoll]
  local newButton = guiElements.pianoRollButtons[n]
  local oldRoll = rolls[selectedRoll]
  local newRoll = rolls[n]

  oldRoll.settings = panel:getSettings()
  oldButton.style.idle[4] = 6/16
  oldButton.style.hover[4] = 6/16
  oldButton.style.active[4] = 6/16
  oldButton.style.clicked[4] = 6/16
 
  panel:setSettings(newRoll.settings)
  newButton.style.idle[4] = 9/16
  newButton.style.hover[4] = 9/16
  newButton.style.active[4] = 9/16
  newButton.style.clicked[4] = 9/16

  selectedRoll = n
end

for i = 1, 12 do
--  local hue = (1/3 + (i-1) * 0.45) % 1
  local hue = (1/3 + (i-1)/12) % 1
  local r, g, b = utils.HSL(hue, 1, 0.6)
  local button = gui:add("button", 80 + 27 * i, 16, i, nil, 24, nil)
  button.style.idle = {utils.HSL(hue, 1, 0.6, 6/16)}
  button.style.hover = {utils.HSL(hue, 1, 0.8, 6/16)}
  button.style.active = {utils.HSL(hue, 1, 0.4, 6/16)}
  button.style.clicked = {utils.HSL(hue, 1, 0.3, 6/16)}
  guiElements.pianoRollButtons[i] = button
  button.callback = function()
    selectPianoRoll(i)
  end
end

modes:init(rolls, guiElements)

local waveforms = {}
local effects = {}
for i, filename in ipairs(love.filesystem.getDirectoryItems("waves")) do
  waveforms[#waveforms + 1] = filename:match("^(.-)%.lua$")
end
for i, filename in ipairs(love.filesystem.getDirectoryItems("effects")) do
  effects[#effects + 1] = filename:match("^(.-)%.lua$")
end

panel:init(gui, instruments, effects)

selectPianoRoll(1)

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
  rolls[selectedRoll]:update(dt)
  gui:update(dt)
end


love.draw = function()
  for i, roll in ipairs(rolls) do
    roll:draw(selectedRoll == i)
  end
  gui:draw()
  modes:draw()
end


local play = function(start, record)
  start = start or 0
  channel:push{action = "clear"}
  rolls[selectedRoll].settings = panel:getSettings()
  for i, roll in ipairs(rolls) do
    local n = roll:getNotes(bpm)
    SQ:pause()
    print(roll.settings)
    local settings = roll.settings or panel:getSettings()
    for i, note in ipairs(n) do
      if note.delay + note.duration > start then
        channel:push{
          action = "start",
          --id = i,
          instrument = settings.instrument,
          attack = settings.attack,
          decay = settings.decay,
          sustain = settings.sustain,
          release = settings.release,
          duration = note.duration,
          delay = note.delay - start,
          frequency = note.pitch,
          amplitude = settings.amplitude,
          effects = {--[[]{type = "vibrato", 6, 1/6}, {type = "flanger"}--[[]]},
        }
      end
    end
  end
  if record then
    print("Recording...")
    channel:push{
      action = "record",
      stop = "auto"
    }
  end
  SQ:play()
  rolls[selectedRoll]:play(bpm)
  rolls[selectedRoll].playback.time = start
end

love.keypressed = function(k, kk, isRepeat)
  if k:match("f(%d%d?)") then
    local n = tonumber(k:match("f(%d%d?)"))
    if n > 0 and n < 13 then
      selectPianoRoll(n)
      return
    end
  end
  print(selectedRoll, rolls[selectedRoll])
  modes:keypressed(k, kk, isRepeat, rolls[selectedRoll])
  local shift = love.keyboard.isDown("lshift", "rshift")
  if k == "space" then
    play(0, shift)
  elseif k == "escape" then
    channel:push{action = "clear"}
    rolls[selectedRoll]:stop()
  elseif k == "up" and shift then
    bpm = bpm + 1
    print("BPM:", bpm)
  elseif k == "down" and shift then
    bpm = bpm - 1
    print("BPM:", bpm)
  end
  rolls[selectedRoll]:keypressed(k, kk, isRepeat)
  gui:keypressed(k, kk, isRepeat)
end

love.keyreleased = function(k, kk)
  
end

love.textinput = function(char)
  gui:textinput(char)
end

love.mousepressed = function(x, y, b)
  local pitch = rolls[selectedRoll]:mousepressed(x, y, b)
  if pitch then
    channel:push {
      action = "start",
      instrument = "square",
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
  if b == 3 then
    local start = (x - rolls[selectedRoll].x - rolls[selectedRoll].scroll.x) / rolls[selectedRoll].scale.x / bpm * 60
    play(start)
  end
end

love.mousemoved = function(x, y, dx, dy)
  rolls[selectedRoll]:mousemoved(x, y)
end

love.mousereleased = function(x, y, b)
  rolls[selectedRoll]:mousereleased(x, y, b)
  gui:mousereleased(x, y, b)
end

love.wheelmoved = function(wx, wy)
  rolls[selectedRoll]:wheelmoved(wx, wy)
  gui:wheelmoved(wx, wy)
end

love.resize = function(w, h)
  for i, roll in ipairs(rolls) do
    roll.width = w - roll.x - 256
    roll.height = h - roll.y - 64
  end

  panel:resize(w, h)
end
