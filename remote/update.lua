local BASE_URL = "https://raw.githubusercontent.com/xPizu/Dumby/main/remote/"

local FILES = {
    "startup.lua",
    "lib/log.lua",
    "lib/sound.lua",
    "lib/ui.lua",
    "commands/start.lua",
    "commands/stop.lua",
    "commands/rescue.lua",
    "commands/status.lua",
    "commands/goto.lua",
    "commands/clear.lua",
    "commands/help.lua",
    "commands/sound.lua",
}

for _, path in ipairs(FILES) do
    io.write("Downloading " .. path .. " ... ")

    local response = http.get(BASE_URL .. path)
    if not response then
        print("Failed to download " .. path)
    else
        local content = response.readAll()
        response.close()
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        print("OK")
    end
end

print("Update complete.")
