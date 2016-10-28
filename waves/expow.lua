local function expow(x) return x > 0.0 and x^x or 1.0 end

return function(x, frequency) return (expow((x * frequency) % 1.0)-0.69)*3 end