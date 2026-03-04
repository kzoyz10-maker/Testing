local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v4.0 - LERP WALK & FAST BREAK" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().EnableAutoClear = getgenv().EnableAutoClear or false
getgenv().ClearDelay = getgenv().ClearDelay or 0.15 
getgenv().HitCount = getgenv().HitCount or 3
getgenv().WalkSpeed = getgenv().WalkSpeed or 16
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ DETEKSI TILE (RADAR PINTAR) ]]
-- ========================================== --
local function IsTileEmpty(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        if not nameStr:find("bg") and not nameStr:find("background") and not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") then
            return false
        end
    end
    return true
end

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

local function GetNextExposedBlock()
    for y = 100, 0, -1 do 
        local isEven = (y % 2 == 0)
        local startX = isEven and 0 or 100
        local endX = isEven and 100 or 0
        local step = isEven and 1 or -1
        
        for x = startX, endX, step do
            if IsTileBreakable(x, y) then
                if IsTileEmpty(x, y + 1) or IsTileEmpty(x - 1, y) or IsTileEmpty(x + 1, y) then
                    return x, y
                end
            end
        end
    end
    return nil, nil
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT (LERP SMART WALK) ]]
-- ========================================== --
local function CustomSmartWalk(targetPos)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Ambil posisi awal dari PlayerMovement (supaya presisi sama server)
    local startPos = (PlayerMovement and PlayerMovement.Position) or hrp.Position
    local distance = (startPos - targetPos).Magnitude
    
    if distance < 1 then return end -- Kalau udah deket, gausah jalan

    -- Hitung estimasi waktu berdasarkan WalkSpeed
    local walkTime = distance / getgenv().WalkSpeed
    local steps = math.floor(walkTime * 45) -- Resolusi step jalan
    
    for i = 1, steps do
        if not getgenv().EnableAutoClear then break end
        local alpha = i / steps
        local currentLerp = startPos:Lerp(targetPos, alpha)
        
        if PlayerMovement then
            PlayerMovement.Position = currentLerp
            PlayerMovement.VelocityX = 0 
            PlayerMovement.VelocityY = 0 
            PlayerMovement.Grounded = true
        else
            hrp.CFrame = CFrame.new(currentLerp)
        end
        task.wait(1/45)
    end
    
    -- Pastikan nyampe pas di titik akhir
    if PlayerMovement then PlayerMovement.Position = targetPos end
    task.wait(0.1) -- Tunggu bentar biar server nge-register kita udah sampai
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (V4 Ultimate)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) getgenv().EnableAutoClear = v end 
})

SecClear:Input({ 
    Title = "Walk Speed (Kecepatan Jalan)", 
    Value = tostring(getgenv().WalkSpeed), 
    Placeholder = "16", 
    Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end 
})

SecClear:Input({ 
    Title = "Break Delay (Kecepatan Hancurin)", 
    Value = tostring(getgenv().ClearDelay), 
    Placeholder = "0.15", 
    Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end 
})

SecClear:Input({ 
    Title = "Hit Count (Berapa kali tonjok)", 
    Value = tostring(getgenv().HitCount), 
    Placeholder = "3", 
    Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end 
})

-- ========================================== --
-- [[ LOGIKA UTAMA ]]
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
                    -- [!] BERDIRI PERSIS 1 BLOK DI ATASNYA
                    local standPos = Vector3.new(targetX * getgenv().GridSize, (targetY + 1) * getgenv().GridSize, currZ)
                    
                    -- Matikan input biar pemain gak ganggu jalan bot
                    if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
                    
                    -- Jalan santai nan mulus pakai Custom Lerp
                    CustomSmartWalk(standPos)
                    
                    if not getgenv().EnableAutoClear then break end
                    
                    -- [!] SISTEM BREAK PABRIK: Pukul beberapa kali pakai delay & tick
                    for i = 1, getgenv().HitCount do
                        if not getgenv().EnableAutoClear then break end
                        
                        local breakTarget = Vector2.new(targetX, targetY)
                        local currentTick = tick() -- Anti Cheat Os.time / Tick
                        
                        pcall(function()
                            if RemoteBreak:IsA("RemoteEvent") then 
                                RemoteBreak:FireServer(breakTarget, currentTick) 
                            else 
                                RemoteBreak:InvokeServer(breakTarget, currentTick) 
                            end
                        end)
                        task.wait(getgenv().ClearDelay)
                    end
                    
                else
                    getgenv().EnableAutoClear = false
                    if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
                    WindUI:Notify({ Title = "Auto Clear Selesai", Content = "Semua blok terekspos sudah hancur!", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)
