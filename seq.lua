love.graphics.setBackgroundColor(2/16, 2/16, 2/16)

local roll = require "seq.pianoroll".new()
roll.x, roll.y = 64, 64

local instruments = require "instruments"

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
end


love.draw = function()
  roll:draw()
end


love.keypressed = function(k, kk, isRepeat)
  if k == "space" then
    channel:push{action = "clear"}
    local n = roll:getNotes(160)
    SQ:pause()
    for i, note in ipairs(n) do
      channel:push{
        action = "start",
        id = i,
        instrument = "saw",
        attack = 0.02,
        decay = 0.3,
        sustain = 0.6,
        release = 0.2,
        duration = note.duration,
        delay = note.delay,
        frequency = note.pitch,
        amplitude = 1,
        effects = {{type = "vibrato", 6, 1/6}, {type = "chorus"}},
      }
    end
    if love.keyboard.isDown("lshift", "rshift") then
      print("Recording...")
      channel:push{
        action = "record",
        stop = "auto"
      }
    end
    SQ:play()
  elseif k == "escape" then
    channel:push{action = "clear"}
  end
  roll:keypressed(k, kk, isRepeat)
end

love.keyreleased = function(k, kk)

end

love.mousepressed = function(x, y, b)
  local pitch = roll:mousepressed(x, y, b)
  if pitch then
    channel:push {
      action = "start",
      instrument = "saw",
      attack = 0.02,
      decay = 0.3,
      sustain = 0.8,
      release = 0.2,
      duration = 0,
      delay = 0,
      frequency = pitch,
      amplitude = 1,
      effects = {{type = "vibrato", 6, 1/6}, {type = "chorus"}},
    }
  end
end

love.mousemoved = function(x, y, dx, dy)
  roll:mousemoved(x, y)
end

love.mousereleased = function(x, y, b)
  roll:mousereleased(x, y, b)
end

love.wheelmoved = function(wx, wy)
  roll:wheelmoved(wx, wy)
end