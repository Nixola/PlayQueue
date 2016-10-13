function love.load(arrrgs)

  SR = 44100
  SL = 256
  SQ = love.audio.newSource(SR,16,1) -- "Queue type"...
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

  notes = {n = 0}
  --[[ TO DO:
  - ADSR (attack (time to peak), decay (time to sustain), sustain (level to sustain), release (time to zero)
  - send single notes events (start-stop), not table of frequencies
  - ???
  - profit
  --]]

  t = {}
  tn = 0

  keys = {
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
  keys[40] = 'a'
  keys[41] = 'w'
  keys[42] = 's'
  keys[43] = 'e'
  keys[44] = 'd'
  keys[45] = 'f'
  keys[46] = 't'
  keys[47] = 'g'
  keys[48] = 'y'
  keys[49] = 'h'
  keys[50] = 'u'
  keys[51] = 'j'
  keys[52] = 'k'
  keys[53] = 'o'
  keys[54] = 'l'
  keys[55] = 'p'
  --acc,avg =  0.0, {}

end

function love.update(dt)
  --if not love.keyboard.isDown(unpack(keys)) then channel:push "stop" end

end

function love.keypressed(kk,k)
  if keys[k] then
    local f = 440 * (2^(1/12))^(keys[k]-49)

    --t[k] = 440 * (2^(1/12))^(keys[k]-49)
    --tn = tn + 1
    --print(f)
    channel:push{
      action = "start",
      id = notes.n,
      instrument = instrument,
      attack = 0.02,
      decay = 0.1,
      sustain = 0.5,
      release = 0.1,
      frequency = f,
    }
    notes[k] = notes.n
    notes.n = notes.n + 1
  elseif k == "f1" then instrument = "sine"
  elseif k == "f2" then instrument = "organ"--]]
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
    if love.timer then
      love.timer.step()
      dt = love.timer.getDelta()
    end
 
    -- Call update and draw
    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
    if love.graphics and love.graphics.isActive() then
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw() end
    end
 
    if love.timer then love.timer.sleep(0.001) end
  end
 
end