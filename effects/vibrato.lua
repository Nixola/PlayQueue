return function(effects, waveforms)
  return {
  init = nil, --explicitly nil as example
  continuous = function(self, state, speed, depth, waveform)
    waveform = waveform or "sine"
    local ratio = 2^(waveforms[waveform](speed, state.ttime) * depth / 12 )
    return {phaseShift = ratio}
  end
  }
end