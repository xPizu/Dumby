local UI = {}

local BUTTON_COLORS = {
    start = colors.green,
    stop = colors.orange,
    rescue = colors.red,
    status = colors.lightBlue,
    goto = colors.purple,
    sound = colors.gray,
    clear = colors.gray,
    help = colors.gray,
}

local function isColor()
    return term.isColor and term.isColor()
end

local function centered(text, width)
    local pad = math.max(0, math.floor((width - #text) / 2))
    return string.rep(" ", pad) .. text
end

-- Draws the fixed header (title, live status, colored command buttons) on
-- whatever terminal is currently active. Returns:
--   rows   -- { [screenRow] = command } for click handling
--   nextY  -- first free row below the header, where the scrolling log
--             window should start
function UI.Draw(commandList, status)
    local w = term.getSize()

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    term.setCursorPos(1, 1)
    if isColor() then term.setBackgroundColor(colors.blue) end
    term.clearLine()
    term.write(centered("DUMBY -- REMOTE CONTROL", w))
    term.setBackgroundColor(colors.black)

    term.setCursorPos(1, 2)
    term.clearLine()
    if isColor() then term.setTextColor(status.online and colors.lime or colors.red) end
    term.write(" " .. (status.online and "ONLINE" or "OFFLINE"))
    term.setTextColor(colors.white)
    if status.fuel then
        term.write(string.format("  fuel=%s ore=%s pos(%d,%d,%d)",
            tostring(status.fuel), tostring(status.ore or 0),
            status.x or 0, status.y or 0, status.z or 0))
    end

    term.setCursorPos(1, 3)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", w))
    term.setTextColor(colors.white)

    local rows = {}
    local y = 4
    for _, cmd in ipairs(commandList) do
        term.setCursorPos(1, y)
        term.clearLine()
        if isColor() then
            term.setBackgroundColor(BUTTON_COLORS[cmd.name] or colors.gray)
            term.setTextColor(colors.white)
        end
        term.write(" " .. cmd.name:upper() .. " ")
        term.setBackgroundColor(colors.black)
        term.write(" " .. cmd.description)
        rows[y] = cmd
        y = y + 1
    end

    term.setCursorPos(1, y)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", w))
    term.setTextColor(colors.white)

    return rows, y + 1
end

return UI
