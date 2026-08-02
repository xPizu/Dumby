local ROBOT = require("classes.robot")

local ok, err = pcall(function() ROBOT:New():Run() end)
if not ok then
    print("[!] FATAL: " .. tostring(err))
    print("Program halted.")
end