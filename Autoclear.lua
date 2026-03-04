local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v3.0 - SMART EXPOSED & WALK" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().EnableAutoClear = getgenv().EnableAutoClear or false
getgenv().ClearDelay = getgenv().ClearDelay or 0.2
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ DETEKSI TILE (RADAR PINTAR) ]]
-- ========================================== --
-- Fungsi cek apakah blok ini KOSONG (bisa dilewati/diinjak)
local function IsTileEmpty(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        -- Kalau ketemu blok padat, berarti tidak kosong
        if not nameStr:find("bg") and not nameStr:find("background") and not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") then
            return false
        end
    end
    return true
end

-- Fungsi cek apakah blok ini BISA DIHANCURKAN
local function IsTileBreakable(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    local hasBreakable = false
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        if not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") and not nameStr:find("bedrock") and nameStr ~= "0" then
            hasBreakable = true
        end
    end
    return hasBreakable
end

-- Fungsi nyari Blok teratas yang "Terekspos" (Atasnya / Sampingnya Kosong)
local function GetNextExposedBlock()
    -- Scan dari atas ke bawah
    for y = 100, 0, -1 do 
        local isEven = (y % 2 == 0)
        local startX = isEven and 0 or 100
        local endX = isEven and 100 or 0
        local step = isEven and 1 or -1
        
        for x = startX, endX, step do
            if IsTileBreakable(x, y) then
                -- Target cuma valid kalau atasnya kosong (bisa berdiri) atau sampingnya kosong
                if IsTileEmpty(x, y + 1) or IsTileEmpty(x - 1, y) or IsTileEmpty(x + 1, y) then
                    return x, y
                end
            end
        end
    end
    return nil, nil
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT ANTI-BLINK ]]
-- ========================================== --
local function SmoothWalkTo(targetPos)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Matikan physics bentar biar gak ditarik balik
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    
    -- Hitung jarak dan waktu jalan natural (WalkSpeed 16)
    local distance = (hrp.Position - targetPos).Magnitude
    local walkTime = distance / 16 

    -- Pakai Tween biar mulus kayak terbang noclip (Gak bakal blink!)
    local tweenInfo = TweenInfo.new(walkTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()

    -- Nyalain physics lagi
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

-- ========================================== --
-- [[ UI SECTION: AUTO CLEAR ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (Smart Walk)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) 
        getgenv().EnableAutoClear = v 
    end 
})

SecClear:Input({ 
    Title = "Break Delay", 
    Value = tostring(getgenv().ClearDelay), 
    Placeholder = tostring(getgenv().ClearDelay), 
    Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end 
})

-- ========================================== --
-- [[ LOGIKA UTAMA: CARI -> JALAN -> HANCURKAN ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnableAutoClear then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local currZ = hrp.Position.Z
                local targetX, targetY = GetNextExposedBlock()
                
                if targetX and targetY then
                    -- Posisi berdiri 1 grid di atas blok yang mau dihancurkan
                    local standPos = Vector3.new(targetX * getgenv().GridSize, (targetY + 1) * getgenv().GridSize, currZ)
                    
                    -- [!] BACA INI KALAU MAU PAKE A-STAR KAMU:
                    -- Kalau kamu mau pakai fungsi Walk pabrik kamu, komen baris SmoothWalkTo ini, 
                    -- trus ganti jadi: AStarWalk(targetX, targetY + 1)
                    SmoothWalkTo(standPos)
                    
                    task.wait(0.1) -- Delay bentar biar stabil sebelum nonjok
                    
                    -- Hancurkan Blok
                    local breakTarget = Vector2.new(targetX, targetY)
                    pcall(function()
                        if RemoteBreak:IsA("RemoteEvent") then 
                            RemoteBreak:FireServer(breakTarget) 
                        else 
                            RemoteBreak:InvokeServer(breakTarget) 
                        end
                    end)
                    
                    task.wait(getgenv().ClearDelay)
                else
                    -- Kalau nilainya nil, berarti map udah rata semua!
                    getgenv().EnableAutoClear = false
                    WindUI:Notify({ Title = "Auto Clear Selesai", Content = "Map sudah rata tidak tersisa!", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)
