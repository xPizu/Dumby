local dfpwm = require("cc.audio.dfpwm")

local MODEM = peripheral.find("modem")
if not MODEM then error("No modem found on this computer.") end
rednet.open(peripheral.getName(MODEM))

local SPEAKER = peripheral.find("speaker")
local PROTOCOL = "dumby"
local BOOT_TIMEOUT = 5
local ALIVE_TIMEOUT = 15

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

-- Boot Check: Wait for Dumby to send a signal, if not received within BOOT_TIMEOUT seconds, assume Dumby is offline.
local function BootCheck()
    ClearScreen()
    PrintHeader()
    print("")
    print("Waiting for Dumby...")

    local _, message = rednet.receive(PROTOCOL, BOOT_TIMEOUT)
    if message == "alive" then
        print("Dumby is online !")
        playOnline()
    else
        print("No signal received during " .. BOOT_TIMEOUT .. "s. Maybe Dumby is offline.")
        playOffline()
    end
    print("")
end

-- Command Loop: Wait for user input and send commands to Dumby. Currently supports 'stop' and 'clear' commands.
local function CommandLoop()
    while true do
        io.write("> ")
        
        local input = read()
        if input == "stop" then
            rednet.broadcast("stop", PROTOCOL)
            print("Return signal sent.")
        elseif input == "start" then
            rednet.broadcast("start", PROTOCOL)
            print("Launch signal sent.")
        elseif input == "clear" then
            clearScreen()
            printHeader()
        else
            print("Unknown command (only 'start', 'stop' and 'clear' are supported for now).")
        end
    end
end

-- Listening Loop: Listen for messages from Dumby. If no message is received within ALIVE_TIMEOUT seconds, assume Dumby is offline.
local function ListenLoop()
    while true do
        local _, message = rednet.receive(PROTOCOL, ALIVE_TIMEOUT)

        if message == "alive" then
            -- Skip
        elseif message == "returning_home" then
            print("[i] Dumby is heading back home.")
            playReturn()

        elseif message == nil then
            print("[!] No signal from Dumby during " .. ALIVE_TIMEOUT .. "s")
            playOffline()
        end
    end
end

-- Launch the program
bootCheck()
parallel.waitForAny(CommandLooop, ListenLoop)