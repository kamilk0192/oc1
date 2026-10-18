-- INITIALIZATION
-- VARIABLES
local component = require("component")
local term  = require("term")
local event = require("event")
local os    = require("os")
local sides = require("sides")

local is_robot = component.isAvailable("robot")
local robot
if is_robot then
    robot = require("robot")
end

local start = {
    x = 0,
    y = 0,
    z = 0
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
    term.clear()
    term.setCursor(1, 1)
    if h then
        io.write("Backspace by wyjść\n\n")
    end
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

    if is_robot then
        start = {
            x = robot.position().x,
            y = robot.position().y,
            z = robot.position().z
        }
        robot.moveTo(start.x, start.y, start.z)
    end

    return 1
end

local function main()
    local _, _, _, code = event.pull("key_down")
    if code == BACKSPACE then 
        return 0
    end

    if is_robot then
        -- 1. PRZECHODZENIE POLA W RZĘDACH (WĄŻ / SERPENTINE)
        for x = 1, farmSize.x do
            for z = 1, farmSize.z do
                -- ZBIÓR (niszczy uprawę pod robotem)
                if robot.detectDown() then
                    robot.swingDown()
                end
                
                -- PLANTOWANIE (sadzi uprawę pod robotem, jeśli ma ją w ekwipunku)
                if robot.count() > 0 then
                    robot.placeDown()
                end

                -- Ruch do przodu w obrębie aktualnego rzędu
                if z < farmSize.z then
                    robot.forward()
                end
            end

            -- Przejście do kolejnego rzędu (zmiana kierunku w zależności od parzystości)
            if x < farmSize.x then
                if x % 2 == 1 then
                    robot.turnRight()
                    robot.forward()
                    robot.turnRight()
                else
                    robot.turnLeft()
                    robot.forward()
                    robot.turnLeft()
                end
            end
        end

        -- 2. POWRÓT DO MIEJSCA STARTOWEGO
        -- Algorytm dopasowuje drogę powrotną w zależności od tego, w którym rogu zakończył się cykl
        if farmSize.x % 2 == 1 then
            robot.turnRight()
            robot.turnRight()
            for z = 2, farmSize.z do
                robot.forward()
            end
            robot.turnRight()
            for x = 2, farmSize.x do
                robot.forward()
            end
            robot.turnRight()
        else
            robot.turnRight()
            for x = 2, farmSize.x do
                robot.forward()
            end
            robot.turnLeft()
        end

        -- 3. ODDawanie PLONÓW DO SKRZYNKI NAD STARTEM
        -- Wyrzuca przedmioty ze slotów 2-16 (zostawiając slot 1 z nasionami)
        for slot = 2, 16 do
            robot.select(slot)
            if robot.count() > 0 then
                robot.dropUp()
            end
        end
        robot.select(1) -- Powrót do slotu z nasionami na kolejny cykl
    end

    return 1
end

-- PROGRAM
if setup() == 0 then return 0 end
clearscreen(true)
term.write("Rozmiar farmy: " .. farmSize.x .. "x" .. farmSize.z .. "\n")
term.write("Rodzaj uprawy: " .. cropType .. "\n")
term.write("Naciśnij dowolny klawisz, aby rozpocząć cykl, lub Backspace, aby wyjść.\n")

-- MAIN LOOP
while true do
    if main() ~= 1 then
        break
    end
    term.write("Cykl zakończony. Naciśnij klawisz, aby uruchomić ponownie.\n")
end