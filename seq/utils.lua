local utils = {}

utils.HSL = function(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return r+m, g+m, b+m, a
end

local entrySort = function(reverse)
    return function(a, b)
        if reverse then a,b = b,a end
        local ta, tb = type(a[1]), type(b[1])
        if ta < tb then
            return true
        elseif ta > tb then
            return false
        elseif ta == "number" then
            return a[1] < b[1]
        else
            return tostring(a[1]) < tostring(b[1])
        end
    end
end

utils.pairs = function(t, reverse)
    local tt = {}
    for i, v in pairs(t) do
        tt[#tt + 1] = {i, v}
    end
    table.sort(tt, entrySort(reverse))
    local i = 1
    return function()
        local v = tt[i]
        if not v then return end
        i = i + 1
        return v[1], v[2]
    end
end

return utils
