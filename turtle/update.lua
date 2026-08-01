local BASE_URL = "https://raw.githubusercontent.com/xPizu/Dumby/main/turtle/"

local FILES = {
    "config.lua",
    "index.lua",
    "classes/navigator.lua",
    "classes/communicator.lua",
    "classes/explorer.lua",
    "classes/robot.lua",
    "classes/managers/fuel.lua",
    "classes/managers/inventory.lua",
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