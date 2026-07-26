# audio

Obsidian Audio Module
Handles music playback, sound effects, and speaker management
Injected by the bundler / init.lua loader; see src/init.lua.

## Methods

### AudioModule.refresh()

Scan for speaker peripherals
Called automatically on first playback or explicitly from engine boot

### AudioModule.isReady()

Check if audio system is ready

- **returns** (`boolean`) 

### AudioModule.getSpeakerCount()

Get number of connected speakers

- **returns** (`number`) 

### AudioModule.setMuted(muted)

Set master mute state

- **muted** (`boolean`) 

### AudioModule.isMuted()

Get master mute state

- **returns** (`boolean`) 

### AudioModule.setVolume(volume)

Set master volume (0.0 - 1.0)

- **volume** (`number`) 

### AudioModule.getVolume()

Get master volume

- **returns** (`number`) 

### AudioModule.playNote(instrument, pitch, volume)

Play a single note on all speakers

- **instrument** (`string|nil`, optional) Instrument name (default: "harp")
- **pitch** (`number|nil`, optional) Pitch value (default: 12)
- **volume** (`number|nil`, optional) Volume 0-3 (default: 1, scaled by master volume)

### AudioModule.registerSfx(name, sequence)

Register a sound effect sequence

- **name** (`string`) SFX identifier
- **sequence** (`table[]`) Array of note events {instrument, pitch, volume, delay}

### AudioModule.playSfx(name)

Play a registered sound effect

- **name** (`string`) SFX identifier

### AudioModule.hasSfx(name)

Check if SFX is registered

- **name** (`string`) SFX identifier

- **returns** (`boolean`) 

### AudioModule.unregisterSfx(name)

Remove a registered SFX

- **name** (`string`) SFX identifier

### AudioModule.getSfxList()

Get all registered SFX names

- **returns** (`string[]`) 

### AudioModule.playSong(songData, loop)

Play a song (background music)

- **songData** (`table`) Song data with {tempo, length, ticks}
- **loop** (`boolean|nil`, optional) Whether to loop (default: false)

### AudioModule.stopSong()

Stop currently playing song

### AudioModule.isSongPlaying()

Check if a song is currently playing

- **returns** (`boolean`) 

### AudioModule.getCurrentSong()

Get currently playing song data

- **returns** (`table|nil`) 

### AudioModule.stopAll()

Stop all audio (SFX threads will complete, song stops immediately)
