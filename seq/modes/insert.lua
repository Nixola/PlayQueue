local Note = require "seq.note"

local pianoRoll = ...

local insert = {
	name = "Insert",
	keys = {key = "i", mods = {ctrl = false, shift = false, alt = false}}
}

local lengths = {
	-- 64th
	-- 32th
	-- 16th
	-- 8th
	-- 4th
	-- half
	-- whole
}


insert.keypressed = function(self, k, kk, isRepeat)
	if tonumber(k) then
		local mx, my = love.mouse.getPosition()
		mx = mx - pianoRoll.x - pianoRoll.scroll.x
		my = my - pianoRoll.y - pianoRoll.scroll.y
		local nx = math.round(mx / pianoRoll.scale.x / pianoRoll.scale.snap) * pianoRoll.scale.snap
    local ny = math.floor(my / pianoRoll.scale.y)
    local note = Note.new(nx, ny, pianoRoll.scale)
    pianoRoll.notes[pianoRoll.set][#pianoRoll.notes[pianoRoll.set] + 1] = note
    note.length = 2 ^ (tonumber(k) - 5)
  end
end

return insert