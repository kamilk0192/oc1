-- ==========================================
-- OPENCOMPUTERS FARMING SCRIPT (Z GEOLYZEREM)
-- ==========================================
---@diagnostic disable: need-check-nil, undefined-field

-- MODULES & DEPENDENCIES
local component = require("component")
local term      = require("term")
local event     = require("event")
local os        = require("os")
local sides     = require("sides")

-- ROBOT & COMPONENTS CHECK
local is_robot = component.isAvailable("robot")
local robot = is_robot and require("robot") or nil

local is_geolyzer = component.isAvailable("geolyzer")
local geolyzer = is_geolyzer and component.geolyzer or nil

-- VARIABLES & CONFIGURATION
local farmSize = { x = 1, z = 1 }
local cropType = ""

-- KEYCODES
local UP_ARROW    = 200
local DOWN_ARROW  = 208
local LEFT_ARROW  = 203
local RIGHT_ARROW = 205
local ENTER       = 28
local BACKSPACE   = 14

-- ==========================================
-- FUNCTIONS
-- ==========================================

local function clearscreen(showHelp)
    term.clear()
    term.setCursor(1, 1)
    if showHelp then
        io.write("Naciśnij Backspace, aby wyjść\n\n")
    end
end

local function renderFarm()
    for row = 1, farmSize.x do
        if row == farmSize.x then
            io.write("[S")
        else
            io.write("[□")
        end
        for col = 1, farmSize.z - 1 do
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
    -- Sprawdzenie czy robot ma Geolyzer (wymagany do sprawdzania dojrzałości)
    if is_robot and not is_geolyzer then
        print("UWAGA: Robot nie posiada komponentu Geolyzer!")
        print("Zainstaluj Geolyzer w robocie, aby działało sprawdzanie dojrzałości.")
        os.sleep(3)
    end

    while true do
        clearscreen(true)
        print("Podaj rozmiar farmy (x↑, z↑):")
        renderFarm()

        local _, _, _, code = event.pull("key_down")
        if code == UP_ARROW then
            farmSize.x = farmSize.x + 1
        elseif code == DOWN_ARROW then
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

    --print("Podaj rodzaj uprawy:")
    cropType = "potato"--io.read()

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
                
                -- SPRADZANIE DOJRZAŁOŚCI I ZBIÓR ZA POMOCĄ GEOLYZERA
                if geolyzer then
                    local blockInfo = geolyzer.analyze(sides.down)
                    
                    if blockInfo then
                        -- Jeśli roślina jest w pełni dojrzała (np. age == 7 dla pszenicy/marchewek)
                        if blockInfo.properties and blockInfo.properties.age == 7 then
                            robot.swingDown() -- Ścina dojrzałą uprawę
                            if robot.count() > 0 then
                                robot.placeDown() -- Sadzi nową
                            end
                        -- Jeśli pole jest puste (czysta ziemia uprawna bez rośliny)
                        elseif blockInfo.name == "minecraft:farmland" then
                            if robot.count() > 0 then
                                robot.placeDown()
                            end
                        end
                        -- Jeśli roślina jeszcze rośnie (age < 7), skrypt ją pomija i nic nie robi!
                    end
                else
                    -- Awaryjny fallback, gdyby jakimś cudem nie było geolyzera (stare zachowanie)
                    if robot.detectDown() then
                        robot.swingDown()
                    end
                    if robot.count() > 0 then
                        robot.placeDown()
                    end
                end

                -- Ruch do przodu w obrębie rzędu
                if z < farmSize.z then
                    robot.forward()
                end
            end

            -- Przejście do kolejnego rzędu
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

        -- 3. ODDAWANIE PLONÓW DO SKRZYNKI (sloty 2-16, zostawiając slot 1)
        for slot = 2, 16 do
            robot.select(slot)
            if robot.count() > 0 then
                robot.dropUp()
            end
        end
        robot.select(1)
    end

    return 1
end

-- ==========================================
-- PROGRAM EXECUTION
-- ==========================================

if setup() == 0 then
    return 0
end

clearscreen(true)
term.write("Rozmiar farmy: " .. farmSize.x .. "x" .. farmSize.z .. "\n")
term.write("Rodzaj uprawy: " .. cropType .. "\n")

-- MAIN LOOP
while true do
    if main() ~= 1 then
        break
    end
end