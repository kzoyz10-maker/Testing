local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v5.0 - PERSISTENT MODFLY & ANTI-FREEZE" 

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
-- [[ SISTEM MODFLY PERMANEN ]]
-- ========================================== --
local ModflyConnection = nil

local function SetModflyState(state)
    if state then
        -- 1. Matikan kontrol player biar bot bebas bergerak
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
        
        -- 2. Kunci gravitasi dan kecepatan setiap frame biar beneran melayang
        if not ModflyConnection then
            ModflyConnection = RunService.Heartbeat:Connect(function()
                if PlayerMovement then
                    pcall(function()
                        PlayerMovement.VelocityX = 0
                        PlayerMovement.VelocityY = 0
                        PlayerMovement.Grounded = true -- Manipulasi game mengira kita napak tanah
                    end)
                else
                    -- Fallback buat game normal
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
                end
            end)
        end
    else
        -- 1. Hentikan penguncian gravitasi
        if ModflyConnection then
            ModflyConnection:Disconnect()
            ModflyConnection = nil
        end
        -- 2. Kembalikan kontrol player (INI YANG BIKIN ANTI-FREEZE)
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
    end
end

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

    local startPos = (PlayerMovement and PlayerMovement.Position) or hrp.Position
    local distance = (startPos - targetPos).Magnitude
    
    if distance < 1 then 
        if PlayerMovement then PlayerMovement.Position = targetPos end
        return 
    end

    local walkTime = distance / getgenv().WalkSpeed
    local steps = math.floor(walkTime * 45) 
    
    for i = 1, steps do
        if not getgenv().EnableAutoClear then break end
        local alpha = i / steps
        local currentLerp = startPos:Lerp(targetPos, alpha)
        
        if PlayerMovement then
            PlayerMovement.Position = currentLerp
        else
            hrp.CFrame = CFrame.new(currentLerp)
        end
        task.wait(1/45)
    end
    
    if getgenv().EnableAutoClear and PlayerMovement then 
        PlayerMovement.Position = targetPos 
    end
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (V5 Anti-Freeze)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) 
        getgenv().EnableAutoClear = v 
        SetModflyState(v) -- Langsung atur Modfly ON/OFF pas tombol dipencet
    end 
})

SecClear:Input({ 
    Title = "Walk Speed", 
    Value = tostring(getgenv().WalkSpeed), 
    Placeholder = "16", 
    Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end 
})

SecClear:Input({ 
    Title = "Break Delay", 
    Value = tostring(getgenv().ClearDelay), 
    Placeholder = "0.15", 
    Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end 
})

SecClear:Input({ 
    Title = "Hit Count", 
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
                    -- Berdiri persis 1 grid di atasnya (Modfly akan menahannya di udara)
                    local standPos = Vector3.new(targetX * getgenv().GridSize, (targetY + 1) * getgenv().GridSize, currZ)
                    
                    CustomSmartWalk(standPos)
                    
                    if not getgenv().EnableAutoClear then break end
                    
                    -- Pukul berkali-kali pakai delay & tick
                    for i = 1, getgenv().HitCount do
                        if not getgenv().EnableAutoClear then break end
                        
                        local breakTarget = Vector2.new(targetX, targetY)
                        local currentTick = tick() 
                        
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
                    -- Map rata, matikan fitur otomatis
                    getgenv().EnableAutoClear = false
                    SetModflyState(false) -- Lepas modfly secara otomatis
                    WindUI:Notify({ Title = "Selesai", Content = "World sudah bersih!", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Antisipasi kalau script dimatikan paksa, kembalikan karakter ke normal
Window:OnClose(function()
    if getgenv().EnableAutoClear then
        getgenv().EnableAutoClear = false
        SetModflyState(false)
    end
end)
