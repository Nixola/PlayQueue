local sin = math.sin
local tau = 2 * math.pi

return function(x, frequency) return sin(x * frequency * tau) end