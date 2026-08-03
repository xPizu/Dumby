local UI = {}

local ACCENT = colors.cyan

local BUTTON_COLORS = {
    start = colors.green,
    stop = colors.orange,
    rescue = colors.red,
    status = colors.lightBlue,
    goto = colors.magenta,
    sound = colors.gray,
    clear = colors.gray,
    help = colors.gray,
}

local BUTTON_W = 10
local BUTTON_H = 3

local function isColor()
    return term.isColor and term.isColor()
end

local function centered(text, width)
    local pad = math.max(0, math.floor((width - #text) / 2))
    return string.rep(" ", pad) .. text
end

local function line(w, char)
    term.setTextColor(isColor() and ACCENT or colors.white)
    term.write(string.rep(char or "-", w))
end

local function pill(text, bg)
    if isColor() then
        term.setBackgroundColor(bg)
        term.setTextColor(colors.black)
    end
    term.write(" " .. text .. " ")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

local function drawButton(x, y, cmd)
    local color = BUTTON_COLORS[cmd.name] or colors.gray
    for row = 0, BUTTON_H - 1 do
        term.setCursorPos(x, y + row)
        if isColor() then term.setBackgroundColor(color) end
        term.write(string.rep(" ", BUTTON_W))
    end
    term.setCursorPos(x, y + 1)
    if isColor() then term.setTextColor(colors.black) end
    term.write(centered(cmd.name:upper(), BUTTON_W))
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function UI.Draw(commandList, status)
    local w = term.getSize()

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    term.setCursorPos(1, 1)
    line(w, "=")

    term.setCursorPos(1, 2)
    if isColor() then term.setBackgroundColor(ACCENT); term.setTextColor(colors.black) end
    term.clearLine()
    term.write(centered(">> DUMBY REMOTE CONTROL <<", w))
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

    term.setCursorPos(1, 3)
    line(w, "=")

    term.setCursorPos(1, 4)
    term.clearLine()
    pill(status.online and "ONLINE" or "OFFLINE", status.online and colors.lime or colors.red)
    if status.simulation then
        term.write(" ")
        pill("SIM", colors.purple)
    end
    if status.fuel then
        term.setTextColor(colors.lightGray)
        term.write(string.format("  fuel:%s  ore:%s  pos(%d,%d,%d)",
            tostring(status.fuel), tostring(status.ore or 0),
            status.x or 0, status.y or 0, status.z or 0))
        term.setTextColor(colors.white)
    end

    term.setCursorPos(1, 5)
    line(w, "-")

    local cols = math.max(1, math.floor((w + 1) / (BUTTON_W + 1)))
    local hitboxes = {}
    local gridTop = 7
    for i, cmd in ipairs(commandList) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = col * (BUTTON_W + 1) + 1
        local y = gridTop + row * (BUTTON_H + 1)

        drawButton(x, y, cmd)
        table.insert(hitboxes, { x1 = x, y1 = y, x2 = x + BUTTON_W - 1, y2 = y + BUTTON_H - 1, cmd = cmd })
    end

    local rowCount = math.ceil(#commandList / cols)
    local nextY = gridTop + rowCount * (BUTTON_H + 1)

    term.setCursorPos(1, nextY)
    line(w, "=")

    return hitboxes, nextY + 1
end

function UI.HitTest(hitboxes, x, y)
    for _, box in ipairs(hitboxes) do
        if x >= box.x1 and x <= box.x2 and y >= box.y1 and y <= box.y2 then
            return box.cmd
        end
    end
    return nil
end

return UI