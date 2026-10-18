-- ==========================================
-- OPENCOMPUTERS ADVANCED HOLO GEOLYZER
-- ==========================================
local component = require("component")
local event     = require("event")
local term      = require("term")

-- Sprawdzamy dostępność wymaganych komponentów
if not component.isAvailable("geolyzer") or not component.isAvailable("hologram") then
    print("Błąd: Wymagany Geolyzer oraz Projektor Hologramów (Tier 2)!")
    return
end

local geolyzer = component.geolyzer
local hologram = component.hologram

-- Konfiguracja hologramu
hologram.clear()
hologram.setScale(1)

-- Paleta kolorów dla Hologramu Tier 2
hologram.setPaletteColor(1, 0x00FF00) -- Zielony (powietrze / miękkie)
hologram.setPaletteColor(2, 0xFFFF00) -- Żółty (standardowy kamień)
hologram.setPaletteColor(3, 0xFF0000) -- Czerwony (twarde bloki / rudy)

-- Domyślny rozmiar skanu oraz offset w dół
local scanSize = { x = 16, z = 16, h = 8, offset = 0 }
local selectedParam = 1 -- 1: Szerokość (X), 2: Głębokość (Z), 3: Wysokość (H), 4: Offset w dół

-- Klawisze sterujące
local UP_ARROW    = 200
local DOWN_ARROW  = 208
local LEFT_ARROW  = 203
local RIGHT_ARROW = 205
local ENTER       = 28
local BACKSPACE   = 14

local function clearscreen(showHelp)
    term.clear()
    term.setCursor(1, 1)
    if showHelp then
        io.write("Naciśnij Backspace, aby wyjść\n\n")
    end
end

local function setupSize()
    while true do
        clearscreen(true)
        print("=== KONFIGURACJA SKANU ===")
        print("Góra / Dół: Wybór parametru")
        print("Lewo / Prawo: Zmiana wartości")
        print("[ENTER]: Zatwierdź  |  [Backspace]: Wyjdź\n")

        print((selectedParam == 1 and "> " or "  ") .. "Szerokość (X): " .. scanSize.x .. " (max 64)")
        print((selectedParam == 2 and "> " or "  ") .. "Głębokość (Z): " .. scanSize.z .. " (max 64)")
        print((selectedParam == 3 and "> " or "  ") .. "Wysokość (H):  " .. scanSize.h .. " (max 64)")
        print((selectedParam == 4 and "> " or "  ") .. "Offset w dół:  " .. scanSize.offset .. " (max 64)\n")

        print(string.format("Obszar: %dx%dx%d | Offset w dół: %d", scanSize.x, scanSize.z, scanSize.h, scanSize.offset))

        local _, _, _, code = event.pull("key_down")
        if code == UP_ARROW then
            selectedParam = selectedParam - 1
            if selectedParam < 1 then selectedParam = 4 end
        elseif code == DOWN_ARROW then
            selectedParam = selectedParam + 1
            if selectedParam > 4 then selectedParam = 1 end
        elseif code == LEFT_ARROW then
            if selectedParam == 1 then
                scanSize.x = math.max(4, scanSize.x - 4)
            elseif selectedParam == 2 then
                scanSize.z = math.max(4, scanSize.z - 4)
            elseif selectedParam == 3 then
                scanSize.h = math.max(4, scanSize.h - 4)
            elseif selectedParam == 4 then
                scanSize.offset = math.max(0, scanSize.offset - 4)
            end
        elseif code == RIGHT_ARROW then
            if selectedParam == 1 then
                scanSize.x = math.min(64, scanSize.x + 4)
            elseif selectedParam == 2 then
                scanSize.z = math.min(64, scanSize.z + 4)
            elseif selectedParam == 3 then
                scanSize.h = math.min(64, scanSize.h + 4)
            elseif selectedParam == 4 then
                scanSize.offset = math.min(64, scanSize.offset + 4)
            end
        elseif code == ENTER then
            if scanSize.x % 2 ~= 0 then scanSize.x = scanSize.x + 1 end
            if scanSize.z % 2 ~= 0 then scanSize.z = scanSize.z + 1 end
            break
        elseif code == BACKSPACE then
            return false
        end
    end
    return true
end

local function doScan()
    hologram.clear()
    print(string.format("Skanowanie obszaru %dx%dx%d (Offset w dół: %d)...", scanSize.x, scanSize.z, scanSize.h, scanSize.offset))

    local chunkW, chunkD, chunkH = 4, 4, 4
    local halfX = scanSize.x / 2
    local halfZ = scanSize.z / 2
    local startY = -scanSize.offset -- Początkowa wysokość skanu pod/nad poziomem urządzenia

    -- Skanowanie paczkami i skalowanie na rozdzielczość hologramu (48x48x32)
    for cy = startY, startY + scanSize.h - 1, chunkH do
        for cx = -halfX, halfX - 1, chunkW do
            for cz = -halfZ, halfZ - 1, chunkD do
                
                local data = geolyzer.scan(cx, cz, cy, chunkW, chunkD, chunkH)
                
                if data then
                    local index = 1
                    for y = 1, chunkH do
                        for z = 1, chunkD do
                            for x = 1, chunkW do
                                local hardness = data[index] or 0
                                index = index + 1
                                
                                local gx = cx + x - 1
                                local gz = cz + z - 1
                                local gy = cy + y - 1
                                
                                if gy >= startY and gy < startY + scanSize.h then
                                    -- Przeliczanie i skalowanie współrzędnych na siatkę hologramu
                                    local hx = math.floor((gx + halfX) / scanSize.x * 48) + 1
                                    local hz = math.floor((gz + halfZ) / scanSize.z * 48) + 1
                                    local relY = gy - startY
                                    local hy = math.floor(relY / scanSize.h * 32) + 1
                                    
                                    local colorIndex = 0
                                    if hardness > 0.1 and hardness < 1.5 then
                                        colorIndex = 1 -- Zielony
                                    elseif hardness >= 1.5 and hardness < 3.0 then
                                        colorIndex = 2 -- Żółty
                                    elseif hardness >= 3.0 then
                                        colorIndex = 3 -- Czerwony
                                    end
                                    
                                    if hx >= 1 and hx <= 48 and hz >= 1 and hz <= 48 and hy >= 1 and hy <= 32 then
                                        hologram.set(hx, hy, hz, colorIndex)
                                    end
                                end
                            end
                        end
                    end
                end
                
            end
        end
    end
    print("Skan zakończony i zrenderowany!")
end

-- Uruchomienie konfiguracji rozmiaru
if not setupSize() then
    hologram.clear()
    return
end

clearscreen(true)
print("=== HOLO GEOLYZER SCANNER ===")
print(string.format("Obszar: %dx%dx%d | Offset w dół: %d", scanSize.x, scanSize.z, scanSize.h, scanSize.offset))
print("Naciśnij [ENTER], aby odświeżyć skan.")
print("Naciśnij [Backspace], aby wyjść.\n")

while true do
    doScan()
    
    while true do
        local _, _, _, code = event.pull("key_down")
        if code == ENTER then -- ENTER (ponowny skan)
            break
        elseif code == BACKSPACE then -- BACKSPACE (wyjście)
            hologram.clear()
            print("Zamykanie programu...")
            return
        end
    end
end