.local dfpwm = require("cc.audio.dfpwm")

local Sound = {}
Sound.__index = Sound

local URLS = {
    online = "https://files.catbox.moe/5mseje.dfpwm",
    offline = "https://files.catbox.moe/yubhv5.dfpwm",
    returning = "https://files.catbox.moe/76gehs.dfpwm",
    alert = "https://files.catbox.moe/b40ehy.dfpwm",
    lowFuel = "https://files.catbox.moe/j0rhvj.dfpwm",
    rescue = "https://files.catbox.moe/gqvhy0.dfpwm",
    inventoryFull = "https://files.catbox.moe/vfrj1y.dfpwm",
}

function Sound.New(speaker)
    return setmetatable({ speaker = speaker }, Sound)
end

function Sound:Play(url, volume)
    if not self.speaker then return end

    local response = http.get(url, nil, true)
    if not response then
        print("[!] Unable to download the sound: " .. url)
        return
    end

    local decoder = dfpwm.make_decoder()
    while true do
        local chunk = response.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        while not self.speaker.playAudio(buffer, volume or 3) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    response.close()
end

function Sound:PlayOnline() self:Play(URLS.online) end
function Sound:PlayOffline() self:Play(URLS.offline) end
function Sound:PlayReturn() self:Play(URLS.returning) end
function Sound:PlayAlert() self:Play(URLS.alert) end
function Sound:PlayLowFuel() self:Play(URLS.lowFuel) end
function Sound:PlayRescue() self:Play(URLS.rescue) end
function Sound:PlayInventoryFull() self:Play(URLS.inventoryFull) end

return Sound
