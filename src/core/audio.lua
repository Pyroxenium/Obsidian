local audio = {
    speakers = {},
    sfx = {},
    currentSong = nil,
    _songThreadId = nil
}

function audio.refresh()
    audio.speakers = { peripheral.find("speaker") }
    if #audio.speakers == 0 then
        local logger = require("core.logger")
        logger.warn("No speakers found. Audio will be disabled.")
    end
end

function audio.playNote(instrument, pitch, volume)
    if not audio.speakers or #audio.speakers == 0 then audio.refresh() end
    for _, s in ipairs(audio.speakers) do
        pcall(s.playNote, instrument or "harp", volume or 1, pitch or 12)
    end
end

function audio.registerSfx(name, sequence)
    audio.sfx[name] = sequence
end

function audio.playSfx(name)
    local sequence = audio.sfx[name]
    if not sequence then return end

    local thread = require("core.thread")
    thread.start(function()
        for _, note in ipairs(sequence) do
            if note.delay then os.sleep(note.delay) end
            audio.playNote(note.instrument, note.pitch, note.volume)
        end
    end)
end

function audio.playSong(songData, loop)
    audio.stopSong()
    audio.currentSong = songData
    local thread = require("core.thread")

    audio._songThreadId = thread.start(function()
        repeat
            local tickTime = 1 / songData.tempo
            for i = 0, songData.length do
                if audio.currentSong ~= songData then return end 

                local notes = songData.ticks[i]
                if notes then
                    for _, note in ipairs(notes) do
                        audio.playNote(note.instrument, note.pitch, note.volume)
                    end
                end
                os.sleep(tickTime)
            end
        until not loop
    end)
end

function audio.stopSong()
    if audio._songThreadId then
        local thread = require("core.thread")
        thread.stop(audio._songThreadId)
        audio._songThreadId = nil
    end
    audio.currentSong = nil
end

audio.refresh()

return audio