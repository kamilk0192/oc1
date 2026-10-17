-- INITIALIZATION
    -- VARIABLES
--local robot = require("robot")
local term  = require("term")
local event = require("event")
local os    = require("os")

local start = {
--    x = robot.position().x,
--    y = robot.position().y,
--    z = robot.position().z
}

local farmSize = {
    x = 1,
    z = 1
}

local cropType = ""

local UP_ARROW      = 200
local DOWN_ARROW    = 208
local LEFT_ARROW    = 203
local RIGHT_ARROW   = 205
local ENTER         = 28
local BACKSPACE     = 14

-- FUNCTIONS
local function clearscreen(h)
    if h then
        io.write("Backspace by wyjść\n\n")
    end
    term.clear()
    term.setCursor(1, 1)
end

local function renderFarm()
    for row = 1, farmSize.x do
            if (row == farmSize.x) then
                io.write("[S")
            else
                io.write("[□")
            end
            for col = 1, farmSize.z-1 do
                io.write("□")
            end
            io.write("]")
            if row == 1 then
                io.write("    " .. farmSize.x .. "x" .. farmSize.z)
            end
            io.write("\n")
        end
end

local function setup()
    while true do
        -- RENDER
        clearscreen(true)
        print("Podaj rozmiar farmy (x↑, z↑):")
        renderFarm()
        -- SCALING FARM BY ARROW KEYS
        local _, _, _, code = event.pull("key_down")
        if code == UP_ARROW then
            farmSize.x = farmSize.x + 1
        elseif code == DOWN_ARROW  then
            farmSize.x = math.max(farmSize.x - 1, 1)
        elseif code == LEFT_ARROW then
            farmSize.z = math.max(farmSize.z - 1, 1)
        elseif code == RIGHT_ARROW then
            farmSize.z = farmSize.z + 1
        elseif code == ENTER then
            break
        elseif code == BACKSPACE then
            return 0
        end
    end


    print("Podaj rodzaj uprawy:")
    cropType = io.read()

    return 1
end

local function main()
    
    return 1
end
-- PROGRAM
if setup() == 0 then return 0 end
clearscreen(true)
term.write("Rozmiar farmy: " .. farmSize.x .. "x" .. farmSize.z .. "\n")
term.write("Rodzaj uprawy: " .. cropType .. "\n")

    --MAIN LOOP
while true do
    if not main() == 1 then
        break
    end
end