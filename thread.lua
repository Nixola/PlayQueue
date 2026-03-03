--PROF_CAPTURE=true
local prof = require "jprof"
prof.connect(true)

local channel, presets = ...

local recording, startRecording, stopRecording, autoStop
local writer = love.thread.newThread("writer.lua")
local writerChannel = love.thread.newChannel()

table.merge = function(to, from) --doubles as shallow clone too!
  to = to or {}
  from = from or {}

  local new = {}
  for i, v in pairs(to) do
    new[i] = type(v) == "table" and table.clone(v) or v
  end
  local cache = {}
  ---[[
  for i = 1, #from do
    new[#new + 1] = from[i]
    cache[i] = true
    --from[i] = nil
  end--]]
  for i, v in pairs(from) do
    if not cache[i] then
      new[i] = type(v) == "table" and table.clone(v) or v
    end
  end
  return new
end

table.clone = function(t)
  return table.merge({}, t)
end

local lerp = function(points, t)
  for i = 1, #points, 2 do
    local x1, y1, x2, y2 = points[i], points[i+1], points[i+2], points[i+3]
    if x1 <= t and x2 and x2 >= t then
      local dx = x2 - x1
      local tt = (t - x1) / dx
      return y1 * (1 - tt) + y2 * tt
    end
  end
  return points[#points]
end

require "love.sound"
require "love.audio"
require "love.timer"

SR = channel:demand()
SL = channel:demand()

source = channel:demand()
buffer = channel:demand()

local sampleLength = 1 / SR
local soundChannels = buffer:getChannelCount()

local bufferArray = {}
for i = 0, SL-1 do
  bufferArray[i] = {}
end

local waveforms = {}
for i, filename in ipairs(love.filesystem.getDirectoryItems("waves")) do
  local waveName = filename:match("^(.-)%.lua$")
  if not waveName then
  	print("Not a Lua file", filename)
  else
  	local r, file = pcall(love.filesystem.load, "waves/" .. filename)
  	if not r then
  	  print("Error loading", filename, file)
  	else
  	  local r, wave = pcall(file)
  	  if not r then
  	  	print("Error executing", filename, wave)
  	  else
  	  	if not type(wave) == "function" then
  	  	  print("Invalid file", filename)
  	  	else
  	  	  waveforms[waveName] = wave
  	  	end
  	  end
  	end
  end
end


local instrs = {}

local effects = {}
for i, filename in ipairs(love.filesystem.getDirectoryItems("effects")) do
  local effectName = filename:match("^(.-)%.lua$")
  if not effectName then
    print("Not a Lua file", filename)
  else
    local r, file = pcall(love.filesystem.load, "effects/" .. filename)
    if not r then
      print("Error loading", filename, file)
    else
      local r, effect = pcall(file)
      if not r then
        print("Error executing", filename, effect)
      else
        if not type(effect) == "function" then
          print("Invalid file", filename)
        else
          effects[effectName] = effect
        end
      end
    end
  end
end

notes = {}
IDs = {}
--[=[ note format:
    - action [string]: either "start" or "release".
     start:
      - id [number/string]: a unique identifier for the note.
      - instrument [string]: instrs[instrument]
      - attack [number]: seconds from start (0 volume) to peak volume (1?)
      - decay [number]: seconds from (attack) peak volume to sustain volume (next)
      - sustain [number[0-1]]: volume level to (hehe) sustain
      - release [number]: seconds from key release (sustain volume) to 0 volume
      - frequency [number]: note frequency. not much to say here.
      - amplitude [number[0-1]]: note amplitude
      --keyshift[number]: number of semitones the note will be shifted up
      --time [number]: time elapsed since last state change
      --phase [number]: phase
      --ttime [number]: time elapsed since note start
      --state [string]: current state (attack, decay, sustain, release)
     release:
      - id [number/string]: a unique identifier for the note.
]=]



--p, d, t = 0.0, (2*math.pi)/SR, 1/SR

local searchNote
searchNote = function(ttime, start, stop)
  start = start or 1
  stop = stop or #notes
  local middle = math.floor((start + stop) / 2)
  if (start == middle) or (stop == middle) then
    return middle + 1
  end
  local note = notes[middle]
  if note.ttime < ttime then
    return searchNote(ttime, start, middle)
  elseif note.ttime > ttime then
    return searchNote(ttime, middle, stop)
  elseif note.ttime == ttime then
    return middle + 1
  end
end

local addNote = function(note, id)
  local ttime = note.ttime
  local tattack = note.attack
  local tdecay = tattack + note.decay
  local tsustain = note.duration
  local trelease = tsustain + note.release
  if ttime < 0 then
    note.state = "delay"
  elseif ttime < tattack then
    note.state = "attack"
    note.time = ttime
  elseif ttime < tdecay then
    note.state = "decay"
    note.time = ttime - tattack
  elseif ttime < tsustain then
    note.state = "sustain"
    note.time = ttime - tdecay
  elseif ttime < trelease then
    note.state = "release"
    note.time = ttime - tsustain
  end
  if not note.state then return end
  if id then
    IDs[id][#IDs[id] + 1] = note
  end
  local index = --[=[]] #notes + 1 --]=] searchNote(note.ttime)
  table.insert(notes, index, note)
end

assemblePreset = function(preset)
  print("Assembling", preset.name)
  preset.action = nil
  local voices = preset.voices
  for i = 1, voices do
  	local voice = presets:pop()
  	preset[i] = voice
  	local effects = voice.effects
  	voice.effects = {}
  	for i = 1, effects do
  	  local effect = presets:pop()
  	  voice.effects[i] = effect
  	end
  end
  instrs[preset.name] = preset
end

local run = true
local syncs = {}
while run do

  -- Receive and handle events
  prof.push("frame")
  prof.push("event input")
  local event = channel:pop()
  while event do
    local action = event.action

    if action == "preset" then
      assemblePreset(event)

    elseif action == "start" then -- start first; gotta go fast
      local id = event.id

      if id then
        IDs[id] = IDs[id] and error("Starting note already exists") or {}
      end
      local sync = syncs[event.sync]
      local baseDelay = sync and sync.time or 0
      for i, voice in ipairs(instrs[event.instrument]) do
        local note = {}
        note.id = id
        note.phase = 0
        note.attack = event.attack
        note.decay = event.decay
        note.sustain = event.sustain
        note.release = event.release
        note.duration = event.duration
        note.delay = event.delay and (event.delay - baseDelay) or 0
        note.ttime = -note.delay
        note.time = math.min(0, note.ttime)
        note.frequency = event.frequency + voice.keyshift
        note.f1 = 440 * 2^((note.frequency - 69) / 12)
        note.bend = event.bend
        note.voice = voice
        note.amplitude = event.amplitude * voice.amplitude
        note.func = waveforms[voice.waveform] --instrs[event.instrument].func
        note.effects = table.merge(voice.effects, event.effects)
        note.pan = event.pan
        local startEffects = {}
        for i = #note.effects, 1, -1 do
          local v = note.effects[i]
          v.effect = effects[v.type](effects, waveforms)
          if v.effect.init then
            startEffects[#startEffects + 1] = v
          end
          if not v.effect.continuous then
            table.remove(note.effects, i)
          end
        end

        for i, v in ipairs(startEffects) do
          for i, v in ipairs(v.effect:init(note, v)) do
            addNote(v, id)
          end
        end

        addNote(note, id)
      end
    elseif action == "change" then
      if IDs[event.id] then
        for i, note in ipairs(IDs[event.id]) do
          note.attack = event.attack or note.attack
          note.decay = event.decay or note.decay
          note.sustain = event.sustain or note.sustain
          note.release = event.release or note.release
          note.duration = event.duration or note.duration
          if event.delay then
            note.ttime = note.ttime + note.delay - event.delay
            note.delay = event.delay
          end
          note.frequency = event.frequency and (event.frequency + note.voice.keyshift) or note.frequency
          note.amplitude = event.amplitude and (event.amplitude * note.voice.amplitude) or note.amplitude
          note.effects = event.effects and table.merge(note.voice.effects, event.effects) or note.effects
        end
      end
    elseif action == "release" then
      if not IDs[event.id] then
        error("Released note doesn't exist")
      end
      for i, note in ipairs(IDs[event.id]) do
        note.time = 0
        if note.delay == 0 then
          note.state = "release"
          note.sustain = note.a
          note.time = 0
        end
        note.duration = note.ttime + note.delay
      end
    elseif action == "end" then
      for i, note in ipairs(IDs[event.id]) do
        note.state = "end"
      end
      IDs[event.id] = nil
    elseif action == "record" then
      if not recording then
        startRecording = true
        if event.stop == "auto" then
          autoStop = true
        end
      end
    elseif action == "stop" then
      if recording then
        stopRecording = true
      end
    elseif action == "clear" then
      if recording then
        stopRecording = true
      end
      for i, v in ipairs(notes) do
        v.state = "end"
      end
      IDs = {}
      syncs = {}
    elseif action == "sync" then
      local sync = {
        id = event.id,
        time = 0,
      }
      syncs[sync.id] = sync
    elseif action == "quit" then
      run = false
    end
    event = channel:pop()
  end
  prof.pop("event input")

  -- If source is running out
  local freeBuffers = source:getFreeBufferCount()
  if freeBuffers > 0 then
    prof.push("synthesize her")
    for i, v in pairs(syncs) do
      v.time = v.time + SL * sampleLength
    end
    local bufferArray = bufferArray
    for i = 0, SL-1 do
      for c = 1, soundChannels do
        bufferArray[i][c] = 0
      end
    end

    local last = 0

    for i, v in ipairs(notes) do
      local time = v.time
      local ttime = v.ttime
      local duration = v.duration
      local state = v.state
      local attack, decay, sustain, release = v.attack, v.decay, v.sustain, v.release
      local amplitude = v.amplitude
      local effects, pan = v.effects, v.pan
      --local f1 = v.f1
      local id = v.id
      local frequency, phase = v.frequency, v.phase
      local bend = v.bend
      print(frequency, ttime, duration)
      if bend then
        print(frequency, ttime, duration)
        frequency = frequency + lerp(bend, ttime / duration)
      end
      local func = v.func
      local f1 = 440 * 2^((frequency - 69) / 12)

      if -ttime > SL * sampleLength then
        break
      end
      last = i

      for i = 0, SL-1 do
        time = time + sampleLength
        ttime = ttime + sampleLength
        f1 = 440 * 2^((frequency - 69) / 12)
        local a = 0
        local calc = true
        if duration and ttime > duration and not (state == "release" or state == "end") then
          state = "release"
          time = 0
        end

        if state == "delay" then
          if ttime > 0 then
            state = "attack"
            time = ttime
          else
            a = 0
            calc = false
          end
        end

        if calc then
          if state == "attack" then
            if time > attack then
              state = "decay"
              time = time - attack
            else
              a = time / attack
            end
          end
          
          if state == "decay" then
            if time > decay then
              state = "sustain"
              time = 0
            else
              local tt = time / decay
              a = 1 * (1 - tt) + sustain * tt
            end
          end

          if state == "sustain" then
            a = sustain
          end

          if state == "release" then
            if time > release then
              if id then
                for ii, vv in ipairs(IDs[id]) do
                  if vv == v then
                    IDs[id][ii] = nil
                    break
                  end
                end
              end
              state = "end"
              calc = false
              a = 0
            else
              local tt = time / release
              a = sustain * (1-tt)
            end
          end

          if calc then
            local n = frequency
            local phaseShift = 1
            local effs = {}
            for i, v in ipairs(effects) do
              effs[i] = v.effect:continuous(ttime, v)
              a = a * (effs[i].amplitude or 1)
              n = n * (effs[i].keyShift or 1)
              phaseShift = phaseShift * (effs[i].phaseShift or 1)
            end
            phase = phase + sampleLength * phaseShift
            for c = 1, soundChannels do
              local a = a
              if pan then
                a = a * pan[c]
              end
              bufferArray[i][c] = bufferArray[i][c] + func(phase, f1) * a * amplitude
            end
          end
        end
      end
      v.time = time
      v.ttime = ttime
      v.a = a
      v.state = state
      v.phase = phase
    end

    for i = 0, SL-1 do
      for c = 1, soundChannels do
        buffer:setSample(i, c, bufferArray[i][c] / 4)
      end
    end
    prof.pop("synthesize her")
    source:queue(buffer)
    source:play()
    prof.push("update")
    for i = last + 1, #notes do
      local v = notes[i]
      v.time = v.time + SL * sampleLength
      v.ttime = v.ttime + SL * sampleLength
    end
    prof.pop("update")
    prof.push("record")
    if startRecording then
      writer:start(writerChannel)
      startRecording = false
      recording = true
    end
    if stopRecording then
      writerChannel:push("stop")
      stopRecording = false
      recording = false
    end
    if recording then
      writerChannel:push(buffer)
    end
    prof.pop("record")
    -- Remove dead notes; best to do it when a buffer's just been pushed
    prof.push("cleanup")
    for i = #notes, 1, -1 do
      local note = notes[i]
      if note.state == "end" then
        table.remove(notes, i)
      end
    end
    prof.pop("cleanup")
    if recording and autoStop and #notes == 0 then
      channel:push{action="stop"}
      print("Recording stopped automatically")
    end
  else
    love.timer.sleep(0.001)
  end
  prof.pop("frame")
end
prof.write("capture.jprof")
--[[
local sin = function(freqtable,ip)
  local phase, increment = (ip or 0), (2*math.pi)/8000/2
  return function(dt)
    phase = phase + increment
    local x = phase * freq
    return math.sin(phase*freq)
  end
end]]


--[[
local sin = function(freqtable,ip)
  local phase, increment = (ip or 0), (2*math.pi)/8000/2
  local time = 0
  return function(dt)
    dt = 1/8000 * 150 / 1.25
    time = time + dt / (2*math.pi*4)
    phase = phase + increment
    local melody = (time / 1.25) * 2
    local freq = freqtable[(math.floor(melody) % 128) + 1]
    —print(type(freqtable))
    —print(math.floor(melody) % 128)
    local x = phase * freq
    —return x < 0 and -1 or 1
    return math.sin(phase*freq)
  end
end]]
