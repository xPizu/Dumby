local BASE_URL = "https://raw.githubusercontent.com/xPizu/Dumby/main/remote/"
local BASALT_URL = "https://cdn.jsdelivr.net/gh/Pyroxenium/Basalt2@basalt2.5/bundle/basalt.lua"

local FILES = {
    "startup.lua",
    "lib/log.lua",
    "lib/sound.lua",
    "lib/theme.lua",
    "ui/dashboard.lua",
    "commands/start.lua",
    "commands/stop.lua",
    "commands/rescue.lua",
    "commands/status.lua",
    "commands/goto.lua",
    "commands/clear.lua",
    "commands/help.lua",
    "commands/sound.lua",
}

local function download(url, path)
    io.write("Downloading " .. path .. " ... ")

    local response = http.get(url)
    if not response then
        print("Failed to download " .. path)
        return
    end

    local content = response.readAll()
    response.close()
    local file = fs.open(path, "w")
    file.write(content)
    file.close()
    print("OK")
end

download(BASALT_URL, "basalt.lua")

for _, path in ipairs(FILES) do
    download(BASE_URL .. path, path)
end

if fs.exists("lib/ui.lua") then
    fs.delete("lib/ui.lua")
    print("Removed stale lib/ui.lua")
end

print("Update complete.")