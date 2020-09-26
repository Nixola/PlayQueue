local channel = ...
local buffers = {}
local start = true
require "love.sound"
require "love.filesystem"

local LE = function(n, len)
  local orig = n
  local t = {}
  while n > 0 do
      table.insert(t, string.char(n%256))
      n = math.floor(n/256)
  end

  while #t < len do table.insert(t, '\0') end
  local s = orig .. " 0x"
  for i, v in ipairs(t) do s = s .. string.format("%x", v:byte()) end
  print(s) 
  return table.concat(t, "")
end

local header = function(soundData, totalBuffers)
  local h = {"RIFF", [3] = "WAVEfmt ", [11] = "data"}
  local depth = soundData:getBitDepth()/8
  local channels = soundData:getChannelCount()
  local samples = soundData:getSampleCount() * totalBuffers
  local rate = soundData:getSampleRate()
  print("Chunk size:")
  h[2] = LE(4 + 28 + 8 + depth * channels * samples, 4) -- chunk size, maybe an issue lies here? No, it didn't
  print("Subchunk size:")
  h[4] = LE(16, 4) -- subchunk size, just 16
  print("Format:")
  h[5] = LE(1, 2)  -- format, just 1
  print("Channels:")
  h[6] = LE(channels, 2) -- number of channels
  print("Sampling rate:")
  h[7] = LE(rate, 4)  -- number of samples per second in each channel
  print("Bytes per second:")
  h[8] = LE(rate * depth * channels, 4) -- number of bytes per second
  print("Bytes per sample (all channels):")
  h[9] = LE(depth * channels, 2) -- block size (bytes per channel)
  print("Sample size in bits:")
  h[10] = LE(depth * 8, 2) -- bits sample size
  print("Data size:")
  h[12] = LE(depth * channels * samples, 4) -- data size, maybe an issue lies here?

  return table.concat(h, "")
end

local filename = os.time() .. ".wav"
--[[
local f, e = io.open(filename, "w")
if f then
  print("Writing to", filename)
else
  print("Error recording to", filename, e)
end--]]

local f = love.filesystem.newFile(filename, "a")

local dump = function(buffers)
  f:write(table.concat(buffers, ""))
end

local chunks = -1
local randomBuffer
while true do
  local buffer = channel:demand()
  if buffer == "stop" then
    dump(buffers)
    chunks = chunks + #buffers
    break
  end
  randomBuffer = buffer
  if start then
    start = false
    buffers[1] = header(buffer, 0)
  end
  buffers[#buffers + 1] = buffer:getString()
  if #buffers == 16 then
    chunks = chunks + 16
    dump(buffers)
    buffers = {}
  end
end
f:seek(0)
f:write(header(randomBuffer, chunks))
f:close()