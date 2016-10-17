# PlayQueue
Play music generated in real-time with LÖVE! This requires version 0.11.0.

This accepts several command line arguments:
* `--samplerate <number>` sets the sample rate (default `44100`)
* `--buffersize <number>` sets the buffer size (default `256`)
* `--attack <number>` sets the attack (seconds) of all the notes ADSR envelope (default `0.02`)
* `--decay <number>` sets the decay (also seconds) of all notes (default `0.05`)
* `--sustain <number>` sets the sustain level (amplitude, 0-1) (default `0.8`)
* `--release <number>` sets the release (again, seconds) of all notes (default `0.05`)
* `--layout <layout>` can be `piano` or `openmpt` to use a built-in layout, or a filename (bar the `.lua` extension) to load a layout file (default `openmpt`)
