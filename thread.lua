local channel, presets = ...

table.merge = function(to, from) --doubles as shallow clone too!
  to = to or {}
  from = from or {}

  local new = {}
  for i, v in pairs(to) do
    new[i] = v
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
      new[i] = v
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

local waveforms = {
  sine = function(p, v) return sin(p*v*tau) end,
  sawtooth = function(p, v) return p * v % 2 - 1 end,
  square = function(p, v) return p * v % 2 > 1 and 1 or -1 end,
  minkQM = function(p, v) return (minkowskiQM(p*v)-p*v) * 7 end,
  expow = function(p, v) return (expow((p*v) % 1.0)-0.69)*3 end,
  cantor = require "waves.cantor",
}
local instrs = {}

local effects
      effects = {
  vibrato = {
    init = nil, --explicitly nil as example
    continuous = function(state, speed, depth, waveform)
      waveform = waveform or "sine"
      local ratio = 2^(waveforms[waveform](speed, state.ttime) * depth / 12 )
      return {phaseShift = ratio}
    end
  },
  echo = {
    init = function(note, delay, amount, depth) --don't even know if this will work
      delay = delay or 0.100 --seconds, needs testing
      amplitude = amplitude or 0.5 --needs testing
      depth = depth or math.ceil(math.log(amplitude, depth))
      local t = {}
      for i = 1, depth do
        t[i] = table.clone(note)
        t[i].delay = delay * i
        t[i].amplitude = t[i].amplitude * amplitude ^ i
      end
      return t
    end
  },
  flanger = {
    init = function(note, shift)
      shift = shift or 0.1
      local t = {}
      note.amplitude = note.amplitude / 2
      t[1] = table.clone(note)
      t[1].frequency = t[1].frequency + shift
      return t
    end
  },
  chorus = {
    init = function(note, shift)
      shift = shift or 0.1
      local n1 = effects.flanger.init(note, shift)[1]
      note.amplitude = note.amplitude * 2
      local n2 = effects.flanger.init(note, -shift)[1]
      return {n1, n2}
    end
  }
}


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
  IDs[id][#IDs[id] + 1] = note
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
  if source:getFreeBufferCount() > 0 then

    local event = channel:pop()
    if event then
      local action = event.action

      if action == "preset" then
      	assemblePreset(event)

      elseif action == "start" then -- start first; gotta go fast
        local id = event.id

        IDs[id] = IDs[id] and error("Starting note already exists") or {}

        for i, voice in ipairs(instrs[event.instrument]) do
          local note = {}
          note.id = id
          note.time = 0
          note.phase = 0
          note.ttime = 0
          note.attack = event.attack
          note.decay = event.decay
          note.sustain = event.sustain
          note.release = event.release
          note.duration = event.duration
          note.delay = event.delay or 0
          note.frequency = event.frequency + voice.keyshift
          note.amplitude = event.amplitude * voice.amplitude
          note.func = waveforms[voice.waveform] --instrs[event.instrument].func
          note.effects = table.merge(voice.effects, event.effects)
          local startEffects = {}
          for i = #note.effects, 1, -1 do
            local v = note.effects[i]
            if effects[v.type].init then
              startEffects[#startEffects + 1] = v
            end
            if not effects[v.type].continuous then
              table.remove(note.effects, i)
            end
          end

          for i, v in ipairs(startEffects) do
            for i, v in ipairs(effects[v.type].init(note, unpack(v))) do
              addNote(v, id)
            end
          end

          addNote(note, id)
        end
      elseif action == "release" then
        if not IDs[event.id] then
          error("Released note doesn't exist")
        end
        for i, note in pairs(IDs[event.id]) do
          note.time = 0
          if note.delay == 0 then
          	note.state = "release"
          	note.sustain = note.a
          	note.time = 0
          end
          note.duration = note.ttime + note.delay
        end
      end
    end

    for i = 0, SL-1 do
      local sample = 0
      local notesN = 0

      for i, note in pairs(notes) do
        local time = note.time + sampleLength
        note.ttime = note.ttime + sampleLength
        --note.phase = note.phase + t

        local a
        if note.state == "delay" then
          if time > note.delay then
            note.state = "attack"
            time = 0
          else
            a = 0
          end
        end
        if note.state == "attack" then
          if time > note.attack then
            note.state = "decay"
            time = 0

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
          if note.duration and note.ttime > note.duration then
            note.state = "release"
            note.time = 0
          end
          a = note.sustain
          notesN = notesN + 1
        end
        if note.state == "release" then
          if time > note.release then
            for ii, vv in pairs(IDs[note.id]) do
              if vv == note then
                IDs[note.id][ii] = nil
                break
              end
            end
            notes[i] = nil
            a = 0
          else
            local tt = time / note.release
            a = note.sustain * (1-tt)
            notesN = notesN + 1
          end
        end
        note.a = a

        local n = note.frequency

        local phaseShift = 1

        local effs = {}
        for i, v in ipairs(note.effects) do
          effs[i] = effects[v.type].continuous(note, unpack(v))
          a = a * (effs[i].amplitude or 1)
          n = n * (effs[i].keyShift or 1)
          phaseShift = phaseShift * (effs[i].phaseShift or 1)
        end


        local f1 = 440 * 2^((n - 49) / 12)
        --local f2 = 440 * 2^((n + sin(tau * 6 * note.ttime)/6 - 49) / 12)
        --local ratio = 2^(sin(tau * 6 * note.ttime)/ 6 / 12 )
        note.phase = note.phase + sampleLength * phaseShift -- f2 / f1
        --io.write(f1, "\t", f2, "\n")
        sample = sample + note.func(note.phase, f1) * a * note.amplitude--instrs[note.instrument](note.phase, f1) * a
        --print(sample)

        note.time = time
      end

      buffer:setSample(i, sample / 4)--notesN)
    end
    source:queue(buffer)
    source:play()
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