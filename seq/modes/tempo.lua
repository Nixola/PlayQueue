local pianoRoll, guiElements = ...

local tempo = {
	name = "Tempo",
	keys = {key = "t", ctrl = false, shift = false, alt = false}
}

tempo.start = function(self)
  guiElements.bpm:focus()
  guiElements.bpm.parentGui:focus()
end

return tempo