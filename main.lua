config = {}

function love.load(arrrgs)

  table.remove(arg, 1)
  for i, v in ipairs(arg) do
    if v:match("^%-%-") then --option
      config[v:match("^%-%-(.-)$")] = true
    else --par
      local o = arg[i-1]:match("^%-%-(.-)$")
      config[o] = v
    end
  end

  SR = tonumber(config.samplerate) or 44100
  SL = tonumber(config.buffersize) or 256
  SQ = love.audio.newQueueableSource(SR,16,1) -- "Queue type"...
  SD = love.sound.newSoundData(SL,SR,16,1) -- Buffer

  thread = love.thread.newThread("thread.lua")
  channel = love.thread.newChannel()
  channel:push(SR)
  channel:push(SL)

  channel:push(SQ)
  channel:push(SD)

  thread:start(channel)

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

  attack = tonumber(config.attack) or 0.02
  decay = tonumber(config.decay) or 0.05
  sustain = tonumber(config.sustain) or 0.8
  release = tonumber(config.release) or 0.05

  layouts = {}
  layouts.openmpt = {
    ["1"] = 28,
    ["2"] = 29,
    ["3"] = 30,
    ["4"] = 31,
    ["5"] = 32,
    ["6"] = 33,
    ["7"] = 34,
    ["8"] = 35,
    ["9"] = 36,
    ["0"] = 37,
    ["-"] = 38,
    ["="] = 39,
    ["q"] = 40,
    ["w"] = 41,
    ["e"] = 42,
    ["r"] = 43,
    ["t"] = 44,
    ["y"] = 45,
    ["u"] = 46,
    ["i"] = 47,
    ["o"] = 48,
    ["p"] = 49,
    ["["] = 50,
    ["]"] = 51,
    ["a"] = 52,
    ["s"] = 53,
    ["d"] = 54,
    ["f"] = 55,
    ["g"] = 56,
    ["h"] = 57,
    ["j"] = 58,
    ["k"] = 59,
    ["l"] = 60,
    [";"] = 61,
    ["'"] = 62,
    ["\\"] = 63,
    ["nonusbackslash"] = 64,
    ["z"] = 65,
    ["x"] = 66,
    ["c"] = 67,
    ["v"] = 68,
    ["b"] = 69,
    ["n"] = 70,
    ["m"] = 71,
    [","] = 72,
    ["."] = 73,
    ["/"] = 74,
  }
  layouts.piano = {
    ["q"] = 40,
    ["2"] = 41,
    ["w"] = 42,
    ["3"] = 43,
    ["e"] = 44,
    ["r"] = 45,
    ["5"] = 46,
    ["t"] = 47,
    ["6"] = 48,
    ["y"] = 49,
    ["7"] = 50,
    ["u"] = 51,
    ["i"] = 52,
    ["9"] = 53,
    ["o"] = 54,
    ["0"] = 55,
    ["p"] = 56,
    ["["] = 57,
    ["="] = 58,
    ["]"] = 59,
    ["nonusbackslash"] = 52,
    ["a"] = 53,
    ["z"] = 54,
    ["s"] = 55,
    ["x"] = 56,
    ["c"] = 57,
    ["f"] = 58,
    ["v"] = 59,
    ["g"] = 60,
    ["b"] = 61,
    ["h"] = 62,
    ["n"] = 63,
    ["m"] = 64,
    ["k"] = 65,
    [","] = 66,
    ["l"] = 67,
    ["."] = 68,
    [";"] = 69,
    ["\\"] = 70,
    ["à"] = 71,
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

end

function love.update(dt)

end

function love.keypressed(kk,k)
  if keys[k] then

    --t[k] = 440 * (2^(1/12))^(keys[k]-49)
    --tn = tn + 1
    --print(f)
    channel:push{
      action = "start",
      id = notes.number,
      instrument = instrument,
      attack = attack,
      decay = decay,
      sustain = sustain,
      release = release,
      frequency = keys[k],
      amplitude = 1,
    }
    notes[k] = notes.number
    notes.number = notes.number + 1
  elseif k == "f1" then instrument = "sine"
  elseif k == "f2" then instrument = "organ"--]]
  elseif k == "f3" then instrument = "flute"
  end
end

function love.keyreleased(kk,k)
  if keys[k] and notes[k] then
  	--t[k] = nil
  	--tn = tn - 1
    --local s = (tn == 0) and stop or t
  	--channel:push(s)
    channel:push{
      action = "release",
      id = notes[k]
    }
    notes[k] = nil
  end
end

love.threaderror = print

function love.run()
 
  if love.math then
    love.math.setRandomSeed(os.time())
  end

  if love.load then love.load(arg) end
 
  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end
 
  local dt = 0

  local tr = 1/60
  local fr = 1/60

  local ua = 0
  local da = 0
 
  -- Main loop time.
  while true do
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end
 
    -- Update dt, as we'll be passing it to update
    love.timer.step()
    dt = love.timer.getDelta()

    ua = ua + dt
    da = da + dt
 
    -- Call update and draw
    if love.update and ua > tr then 
      love.update(dt)
      ua = ua % tr
    end -- will pass 0 if love.timer is disabled
 
    if da > fr and love.graphics and love.graphics.isActive() then
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw() end
      love.graphics.present()
      da = da % fr
    end
 
    love.timer.sleep(0.001)
  end
 
end