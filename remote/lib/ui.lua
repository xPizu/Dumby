local UI = {}

function UI.Clear()
    term.clear()
    term.setCursorPos(1, 1)
end

function UI.PrintHeader(commandList)
    print("Dumby -- Remote Control")
    print("")
    print("Commands:")
    for _, cmd in ipairs(commandList) do
        print("  " .. cmd.name .. " -- " .. cmd.description)
    end
    print("")
    print("Ctrl + T to quit.")
end

return UI
