local modes = {}

modes.init = function(self, ...)
	self.modes = {}
	local dir = love.filesystem.getDirectoryItems("seq/modes/")
	for i, file in ipairs(dir) do
		local f = love.filesystem.load("seq/modes/" .. file)
		local success, mode = pcall(f, ...)
		if not success then
			error(mode)
		end
		self.modes[mode.name] = mode
		mode = mode.insert --change to mode.normal
		-- insert inserts note, either by click-dragging or by pressing keys
		-- escape reverts to normal, which lets you select notes; selected notes can be deleted, dragged around, copied, pasted
		-- t enters tempo mode, to change tempo; remove that ugly box in the top-left
	end
end


modes.draw = function(self)
	if self.mode and self.mode.name then
		local w, h = love.graphics.getDimensions()
		local font = love.graphics.getFont()
		love.graphics.setColor(14/16, 14/16, 14/16)
		love.graphics.print(self.mode.name, 8, h - font:getHeight() - 8)
	end
end


modes.mousepressed = function(self, x, y, b)
	if self.mode.mousepressed then
		self.mode:mousepressed(x, y, b)
	end
end


modes.keypressed = function(self, k, kk, isRepeat)
	if self.mode.keypressed then
		self.mode:keypressed(k, kk, isRepeat)
	end
end

return modes