local channel = ...

require "love.sound"
require "love.audio"
require "love.timer"

SR = channel:demand()
SL = channel:demand()

source = channel:demand()
buffer = channel:demand()

local tau = 2 * math.pi
local t = 1/SR

local sin = math.sin
local instrs = {
    sine = function(p, v) return sin(p*v*tau)*.95 end,
    organ = function(p, v) local pv = p*v*tau; return (sin(pv)+sin(pv*2)+sin(pv*4)+sin(pv*8)+sin(pv/2))/5.25 end
}

notes = {}
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
      --time [number]: time elapsed since last state change
      --phase [number]: phase
      --ttime [number]: time elapsed since note start
      --state [string]: current state (attack, decay, sustain, release)
     release:
      - id [number/string]: a unique identifier for the note.
]=]



--p, d, t = 0.0, (2*math.pi)/SR, 1/SR



while true do
  if source:getFreeBufferCount() > 0 then

    local event = channel:pop()
    if event then
      local action = event.action

      if action == "start" then -- start first; gotta go fast
        local id = event.id

        notes[id] = notes[id] and error("Starting note already exists") or event
        event.time = 0
        event.phase = 0
        event.ttime = 0
        event.state = "attack"
      elseif action == "release" then
        local id = event.id
        local note = notes[id]
        if not note then
          error("Released note doesn't exist")
        else
          note.time = 0
          note.state = "release"
        end
      end
    end

    for i = 0, SL-1 do
      local sample = 0
      local notesN = 0

      for i, note in pairs(notes) do
        local time = note.time + t
        note.ttime = note.ttime + t
        --note.phase = note.phase + t

        local a
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
          a = note.sustain
          notesN = notesN + 1
        end
        if note.state == "release" then
          if time > note.release then
            notes[note.id] = nil
            a = 0
          else
            local tt = time / note.release
            a = note.sustain * (1-tt)
            notesN = notesN + 1
          end
        end
        local n = note.frequency

        local f1 = 440 * 2^((n - 49) / 12)
        --local f2 = 440 * 2^((n + sin(tau * 6 * note.ttime)/6 - 49) / 12)
        local ratio = 2^(sin(tau * 6 * note.ttime)/ 6 / 12 )
        note.phase = note.phase + t * ratio -- f2 / f1
        --io.write(f1, "\t", f2, "\n")
        sample = sample + instrs[note.instrument](note.phase, f1) * a
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