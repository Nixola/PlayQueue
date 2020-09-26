local ui = {}
local mt = {__index = ui}

ui.lightUp = {6/16, 6/16, 6/16}
ui.lightDown={12/16, 12/16, 12/16}
ui.darkUp  = {1/16, 1/16, 1/16}
ui.darkDown= {8/16, 8/16, 8/16}

ui.mods = {
  lctrl = 1,
  rctrl = 1,
  lshift = 2,
  rshift = 2,
  lalt = 3,
}

ui.new = function(filename)
  local t = setmetatable({}, mt)
  t.img = love.graphics.newImage(filename)

  t.palette = love.graphics.newCanvas(256, 4)
  --[[
    Palette pixels from 1 to 127 are dedicated to white keys of the corresponding note.
    Pixels from 128 to 255 are the black keys of the corresponding note.
    Both are drawn to when a key is pressed.
  ]]
  t.palette:setFilter("nearest", "nearest")
  t.shader = love.graphics.newShader [[
    extern Image palette;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) { 
      vec4 tex_color = texture2D(texture, texture_coords);
      vec2 index = vec2(tex_color.r, tex_color.g); //get color based on red and green! w00t
      return texture2D(palette, index);
    }]]

  t.shader:send("palette", t.palette)

  love.graphics.setCanvas(t.palette)
    -- keys portion of the palette
    love.graphics.setColor(t.lightUp)
    love.graphics.rectangle("fill", 1.5, 0.5, 127, 1) -- we want the first pixel empty
    love.graphics.setColor(t.darkUp)
    love.graphics.rectangle("fill", 128.5, 0.5, 128, 1)
    -- modifiers portion of the palette
    love.graphics.rectangle("fill", 0.5, 3.5, 255, 1)
  love.graphics.setCanvas()

  return t
end

ui.draw = function(self)
  love.graphics.setColor(1, 1, 1)
  if self.debug then
    love.graphics.draw(self.palette, 0, 0, 0, 3, 3)
  end
  love.graphics.setShader(self.shader)
    love.graphics.draw(self.img, 0, 0)
  love.graphics.setShader()
end

ui.noteDown = function(self, note)
  love.graphics.setCanvas(self.palette)
    love.graphics.setColor(self.lightDown)
    love.graphics.rectangle("fill", note + 1 - 0.5, 0.5, 1, 1)
    love.graphics.setColor(self.darkDown)
    love.graphics.rectangle("fill", note + 1 + 127.5, 0.5, 1, 1)
  love.graphics.setCanvas()
end

ui.noteUp = function(self, note)
  love.graphics.setCanvas(self.palette)
    love.graphics.setColor(self.lightUp)
    love.graphics.rectangle("fill", note + 1 - 0.5, 0.5, 1, 1)
    love.graphics.setColor(self.darkUp)
    love.graphics.rectangle("fill", note + 1 + 127.5, 0.5, 1, 1)
  love.graphics.setCanvas()
end

ui.modDown = function(self, mod)
  love.graphics.setCanvas(self.palette)
    love.graphics.setColor(self.darkDown)
    love.graphics.rectangle("fill", 0.5 + self.mods[mod], 3.5, 1, 1)
  love.graphics.setCanvas()
end

ui.modUp = function(self, mod)
  love.graphics.setCanvas(self.palette)
    love.graphics.setColor(self.darkUp)
    love.graphics.rectangle("fill", 0.5 + self.mods[mod], 3.5, 1, 1)
  love.graphics.setCanvas()
end

return ui