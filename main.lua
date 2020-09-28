local layouts = require "layouts"
local UI, ui = require "ui"
require "run"

local config = {}
local lastRandomKey

local instruments = require "instruments"

local settings = require "settings"

local startRecording = false
local recording = false
local stopRecording = false

-- Push a preset onto the preset channel to the synth thread
local pushPreset = function(preset, name)
  print("Pushing", name)
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

function love.load(arrrgs)

  for i, v in pairs(arg) do print(i, v) end
  print "arr"
  for i, v in pairs(arrrgs) do print(i, v) end

  table.remove(arg, 1)
  for i, v in ipairs(arg) do
    if v:match("^%-%-") then --option
      config[v:match("^%-%-(.-)$")] = true
    else --par
      local o = arg[i-1]:match("^%-%-(.-)$")
      config[o] = v
    end
  end
  if config.seq then
    require "seq"
    return
  end

  ui = UI.new("ui.png")

  SR = tonumber(config.samplerate) or 44100
  SL = tonumber(config.buffersize) or 512
  SQ = love.audio.newQueueableSource(SR,16,1, 4) -- "Queue type"...
  SD = love.sound.newSoundData(SL,SR,16,1) -- Buffer

  thread = love.thread.newThread("thread.lua")
  channel = love.thread.newChannel()
  presets = love.thread.newChannel()
  channel:push(SR)
  channel:push(SL)

  channel:push(SQ)
  channel:push(SD)

  thread:start(channel, presets)

  for i, v in pairs(instruments) do
    pushPreset(v, i)
  end

  instrument = "sine"

  love.graphics.present()

  notes = {number = 0}
  --[[ TO DO:
  - ADSR (attack (time to peak), decay (time to sustain), sustain (level to sustain), release (time to zero)
  - send single notes events (start-stop), not table of frequencies
  - ???
  - profit
  --]]

  t = {}
  tn = 0

  config.attack = tonumber(config.attack) or 0.02
  config.decay = tonumber(config.decay) or 0.05
  config.sustain = tonumber(config.sustain) or 0.8
  config.release = tonumber(config.release) or 0.05
  config.duration = tonumber(config.duration)

  settings.attack = config.attack
  settings.decay = config.decay
  settings.sustain = config.sustain
  settings.release = config.release
  settings.duration = config.duration

  settings.defaults.attack = config.attack
  settings.defaults.decay = config.decay
  settings.defaults.sustain = config.sustain
  settings.defaults.release = config.release
  settings.defaults.duration = config.duration

  instruments = {
    {name = "sine", display = "Sine"},
    {name = "organ", display = "Organ", attack = 0.1},
    {name = "flute", display = "Voice (?)", attack = 0.1},
    {name = "saw", display = "Saw wave"},
    {name = "square", display = "Square wave"},
    {name = "minkQM", display = "Strings...?", attack = 0.1},
    {name = "minkQM1", display = "Pizz. strings...???", attack = 0, decay = 0.15, sustain = 0.2, duration = 0},
    {name = "vibraphone", display = "Vibraphone - like thing???", attack = 0, decay = .3, sustain = 0.1, duration = 0},
    {name = "test", display = "I don't even know", attack = 0, release = .2},
  }

  if not config.layout then
    keys = layouts.openmpt
  elseif layouts[config.layout] then
    keys = layouts[config.layout]
  else
    local p, t = pcall(love.filesystem.load, config.layout .. ".lua")
    if p then 
      keys = t() --I'm assuming you're not an idiot with that property.
    else
      keys = layouts.openmpt
    end
  end

  if tonumber(config.shift) then
    for i, v in pairs(keys) do
      keys[i] = v + config.shift
    end
  end

  love.keyboard.setKeyRepeat(true)

end


function love.update(dt)

end


function love.draw()
  ui:draw()

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(settings:format(), 0, 40)

  for i, v in ipairs(instruments) do
    if instrument == v.name then
      love.graphics.setColor(1,1,1)
    else
      love.graphics.setColor(.5,.5,.5)
    end
    local x = math.floor(800 / #instruments * (i - 1))
    love.graphics.printf("F" .. i .. "\n" .. v.display, x, 0, 800/#instruments, "center")
  end
end


function love.keypressed(kk,k, isRepeat)
  local ctrl = love.keyboard.isDown("lctrl", "rctrl")
  local shift = love.keyboard.isDown("lshift", "rshift")
  local alt = love.keyboard.isDown("lalt")
  if settings.keys[k] then
    settings:keypressed(k)
    return
  end

  if isRepeat then
    return
  end

  if k == "space" then
    local note = love.math.random(40, 51)
    for i, v in pairs(keys) do
      if v == note then
        k = i
        lastRandomKey = k
      end
    end
  end

  if keys[k] then
    if startRecording then
      channel:push{action = "record"}
      startRecording = false
      recording = true
    end

    local effects = {}
    if shift then
      effects[1] = {type = "vibrato", 6, 1/4}
    end
    channel:push{
      action = "start",
      id = notes.number,
      instrument = instrument,
      attack = settings.attack,
      decay = settings.decay,
      sustain = settings.sustain,
      release = settings.release,
      duration = settings.duration,
      frequency = keys[k],
      amplitude = 1,
      effects = effects,
    }

    ui:noteDown(keys[k])
    notes[k] = notes.number
    notes.number = notes.number + 1

  elseif k:match("f[0-9]+") then
    local n = tonumber(k:match("f([0-9]+)"))
    if shift then
      if instruments[n] then
        instruments[n].attack = settings.attack or settings.defaults.attack or config.attack
        instruments[n].decay = settings.decay or settings.defaults.decay or config.decay
        instruments[n].sustain = settings.sustain or settings.defaults.sustain or config.sustain
        instruments[n].release = settings.release or settings.defaults.release or config.release
        instruments[n].duration = settings.duration or settings.defaults.duration or config.duration
      end
    else
      if instruments[n] then
        instrument = instruments[n].name
        settings.attack = instruments[n].attack or config.attack
        settings.decay = instruments[n].decay or config.decay
        settings.sustain = instruments[n].sustain or config.sustain
        settings.release = instruments[n].release or config.release
        settings.duration = instruments[n].duration or config.duration
      end
    end
  end

  if UI.mods[k] then
    ui:modDown(k)
  end

  if k == "insert" then
    if not recording then
      startRecording = not startRecording
    else
      print("Recording stopped")
      recording = false
      channel:push{action="stop"}
    end
  end

end

function love.keyreleased(kk,k)
  if k == "space" then
    k = lastRandomKey
  end
  if keys[k] and notes[k] then
    --t[k] = nil
    --tn = tn - 1
    --local s = (tn == 0) and stop or t
    --channel:push(s)
    channel:push{
      action = "release",
      id = notes[k]
    }

    ui:noteUp(keys[k])
    notes[k] = nil
  end

  if UI.mods[k] then
    ui:modUp(k)
  end
end

love.threaderror = print