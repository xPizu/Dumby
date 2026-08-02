local dfpwm = require("cc.audio.dfpwm")

local MODEM = peripheral.find("modem")
if not MODEM then error("No modem found on this computer.") end
rednet.open(peripheral.getName(MODEM))

local SPEAKER = peripheral.find("speaker")
local PROTOCOL = "dumby"
local REMOTE_HOSTNAME = "dumby-remote"
local BOOT_TIMEOUT = 5
local ALIVE_TIMEOUT = 15

rednet.host(PROTOCOL, REMOTE_HOSTNAME)

-- No live rednet.lookup here: it's a blocking network round-trip and doing
-- it per-message caused missed heartbeats and dropped stop commands. We
-- trust the first sender we ever hear from on this protocol and lock onto
-- them -- fine for a 1-to-1 turtle/remote pairing.
local turtleId = nil

local SOUND_ONLINE_URL = "https://files.catbox.moe/5mseje.dfpwm"
local SOUND_OFFLINE_URL = "https://files.catbox.moe/yubhv5.dfpwm"
local SOUND_RETURN_URL = "https://files.catbox.moe/76gehs.dfpwm"

-- Sound: Function to play a sound from a given URL using the speaker peripheral. It downloads the sound file, decodes it, 
-- and plays it through the speaker at the specified volume.
local function PlaySoundFromUrl(url, volume)
    if not SPEAKER then return end

    local response = http.get(url, nil, true)
    if not response then
        print("[!] Unable to download the sound : " .. url)
        return
    end

    local decoder = dfpwm.make_decoder()
    while true do
        local chunk = response.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        while not SPEAKER.playAudio(buffer, volume or 3) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    response.close()
end

local function PlayOnline() PlaySoundFromUrl(SOUND_ONLINE_URL)  end
local function PlayOffline() PlaySoundFromUrl(SOUND_OFFLINE_URL) end
local function PlayReturn() PlaySoundFromUrl(SOUND_RETURN_URL)  end

-- Screen: Functions for clearing the screen and printing the header
local function ClearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function PrintHeader()
    print("Dumby -- Remote Control")
    print("Type 'start' to launch Dumby's exploration.")
    print("Type 'stop' to ask Dumby to return home.")
    print("Type 'clear' to clear the screen.")
    print("Ctrl + T to quit.")
end

local function Log(msg) print("[Remote] " .. msg) end

-- Boot Check: Wait for Dumby to send a signal, if not received within BOOT_TIMEOUT seconds, assume Dumby is offline.
local function BootCheck()
    ClearScreen()
    PrintHeader()
    print("")
    Log("Waiting for Dumby...")

    local senderId, message = rednet.receive(PROTOCOL, BOOT_TIMEOUT)
    if message == "alive" then
        turtleId = senderId
        Log("Dumby is online!")
        PlayOnline()
    else
        Log("No signal received during " .. BOOT_TIMEOUT .. "s. Maybe Dumby is offline.")
        PlayOffline()
    end
    print("")
end

-- Command Loop: Wait for user input and send commands to Dumby. Currently supports 'stop' and 'clear' commands.
local function CommandLoop()
    while true do
        io.write("> ")

        local input = read()
        if input == "stop" or input == "start" then
            -- Fall back to broadcast if we haven't heard from Dumby yet:
            -- the turtle locks onto whoever it hears from first, so this
            -- first command still gets through and completes the pairing.
            if turtleId then
                rednet.send(turtleId, input, PROTOCOL)
            else
                rednet.broadcast(input, PROTOCOL)
            end
            Log((input == "stop" and "Return" or "Launch") .. " signal sent.")
        elseif input == "clear" then
            ClearScreen()
            PrintHeader()
        else
            Log("Unknown command (only 'start', 'stop' and 'clear' are supported for now).")
        end
    end
end

-- Listening Loop: Listen for messages from Dumby. If no message is received within ALIVE_TIMEOUT seconds, assume Dumby is offline.
local function ListenLoop()
    while true do
        local senderId, message = rednet.receive(PROTOCOL, ALIVE_TIMEOUT)

        if not turtleId and senderId then
            turtleId = senderId
        end

        if message ~= nil and senderId ~= turtleId then
            -- Ignore messages from anyone but our own turtle
        elseif message == "alive" then
            -- Skip
        elseif message == "returning_home" then
            Log("Dumby is heading back home.")
            PlayReturn()

        elseif message == nil then
            Log("No signal from Dumby during " .. ALIVE_TIMEOUT .. "s")
            PlayOffline()
        end
    end
end

-- Launch the program
BootCheck()
parallel.waitForAny(CommandLoop, ListenLoop)