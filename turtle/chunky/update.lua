local BASE_URL = "https://raw.githubusercontent.com/xPizu/Dumby/main/turtle/"

local FILES = {
    { remotePath = "config.lua", localPath = "config.lua" },
    { remotePath = "classes/communicator.lua", localPath = "classes/communicator.lua" },
    { remotePath = "classes/managers/fuel.lua", localPath = "classes/managers/fuel.lua" },
    { remotePath = "chunky/index.lua", localPath = "index.lua" },
}

for _, entry in ipairs(FILES) do
    io.write("Downloading " .. entry.remotePath .. " ... ")

    local response = http.get(BASE_URL .. entry.remotePath)
    if not response then
        print("Failed to download " .. entry.remotePath)
    else
        local content = response.readAll()
        response.close()
        local file = fs.open(entry.localPath, "w")
        file.write(content)
        file.close()
        print("OK")
    end
end

print("Update complete.")