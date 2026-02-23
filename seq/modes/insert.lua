local Note = require "seq.note"

--local pianoRoll = ...

local insert = {
	name = "Insert",
	keys = {key = "i", ctrl = false, shift = false, alt = false}
}


insert.keypressed = function(self, k, kk, isRepeat, pianoRoll)
	if tonumber(k) and tonumber(k) > 0 then
		local mx, my = love.mouse.getPosition()
		if not pianoRoll:aabb(mx, my, 0, 0) then return end
		mx = mx - pianoRoll.x - pianoRoll.scroll.x
		my = my - pianoRoll.y - pianoRoll.scroll.y
		local nx = math.round(mx / pianoRoll.scale.x / pianoRoll.scale.snap) * pianoRoll.scale.snap
    local ny = math.floor(my / pianoRoll.scale.y)
    local note = Note.new(nx, ny, pianoRoll.scale)
    pianoRoll:addNotes(note)
--    pianoRoll.notes[pianoRoll.set][#pianoRoll.notes[pianoRoll.set] + 1] = note
    note.length = 2 ^ (tonumber(k) - 5)
  end
end

return insert
