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

require "love.sound"
require "love.audio"
require "love.timer"

SR = channel:demand()
SL = channel:demand()

source = channel:demand()
buffer = channel:demand()

local sampleLength = 1 / SR


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

local addNote = function(note, id)
  note.state = note.delay > 0 and "delay" or "attack"
  if id then
    IDs[id][#IDs[id] + 1] = note
  end
  notes[#notes + 1] = note
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


while true do

  -- Receive and handle events
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

      for i, voice in ipairs(instrs[event.instrument]) do
        local note = {}
        note.id = id
        note.time = 0
        note.phase = 0
        note.attack = event.attack
        note.decay = event.decay
        note.sustain = event.sustain
        note.release = event.release
        note.duration = event.duration
        note.delay = event.delay or 0
        note.ttime = -note.delay
        note.frequency = event.frequency + voice.keyshift
        note.voice = voice
        note.amplitude = event.amplitude * voice.amplitude
        note.func = waveforms[voice.waveform] --instrs[event.instrument].func
        note.effects = table.merge(voice.effects, event.effects)
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
    end

    event = channel:pop()
  end

  -- If source is running out
  if source:getFreeBufferCount() > 0 then

    for i = 0, SL-1 do
      -- Synthesize her
      --               e
      local sample = 0
      local notesN = 0

      for i, note in ipairs(notes) do
        local time = note.time + sampleLength  -- time and note.time are the elapsed time since the last state change
        note.ttime = note.ttime + sampleLength -- note.ttime is the total time the note has lived

        local a = 0

        if note.duration and note.ttime > note.duration and not (note.state == "release" or note.state == "end") then
          note.state = "release"
          note.time = 0
          time = 0
        end

        if note.state == "delay" then
          --if time > note.delay then
          if note.ttime > 0 then
            note.state = "attack"
            time = note.ttime
          else
            a = 0
          end
        end

        if note.state == "attack" then
          if time > note.attack then
            note.state = "decay"
            time = time - note.attack
          else
            a = time / note.attack
            notesN = notesN + 1
          end
        end

        if note.state == "decay" then
          if time > note.decay then
            note.state = "sustain"
            time = 0
          else
            local tt = time / note.decay
            a = 1 * (1-tt) + note.sustain * tt
            notesN = notesN + 1
          end
        end

        if note.state == "sustain" then
          a = note.sustain
          notesN = notesN + 1
        end

        if note.state == "release" then
          if time > note.release then
            if note.id then
              for ii, vv in ipairs(IDs[note.id]) do
                if vv == note then
                  IDs[note.id][ii] = nil
                  break
                end
              end
            end
            --notes[i] = nil
            note.state = "end"
            a = 0
          else
            local tt = time / note.release
            a = note.sustain * (1-tt)
            notesN = notesN + 1
          end
        end

        if not (note.state == "end" or note.state == "delay") then -- entirely skip over processing dead notes

          note.a = a -- used when releasing a note before sustain kicks in

          local n = note.frequency

          local phaseShift = 1

          local effs = {}
          for i, v in ipairs(note.effects) do
            effs[i] = v.effect:continuous(note, v)
            a = a * (effs[i].amplitude or 1)
            n = n * (effs[i].keyShift or 1)
            phaseShift = phaseShift * (effs[i].phaseShift or 1)
          end


          local f1 = 440 * 2^((n - 69) / 12)
          note.phase = note.phase + sampleLength * phaseShift -- f2 / f1
          sample = sample + note.func(note.phase, f1) * a * note.amplitude


        end
        note.time = time
      end

      buffer:setSample(i, sample / 4)--notesN)
    end

    source:queue(buffer)
    source:play()
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
    -- Remove dead notes; best to do it when a buffer's just been pushed
    for i = #notes, 1, -1 do
      local note = notes[i]
      if note.state == "end" then
        table.remove(notes, i)
      end
    end
    if recording and autoStop and #notes == 0 then
      channel:push{action="stop"}
      print("Recording stopped automatically")
    end
  end
  love.timer.sleep(0.001)
end

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
