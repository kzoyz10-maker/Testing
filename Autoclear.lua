local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v7.0 - DYNAMIC PATHING & BUG FIX" 

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
        if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end
        if not ModflyConnection then
            ModflyConnection = RunService.Heartbeat:Connect(function()
                if PlayerMovement then
                    pcall(function()
                        PlayerMovement.VelocityX = 0
                        PlayerMovement.VelocityY = 0
                        PlayerMovement.Grounded = true 
                    end)
                end
            end)
        end
    else
        if ModflyConnection then
            ModflyConnection:Disconnect()
            ModflyConnection = nil
        end
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

local function IsBedrockInGrid(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        if tostring(tileString):lower():find("bedrock") then return true end
    end
    return false
end

local function IsTileBreakable(gridX, gridY)
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    local hasBreakable = false
    local isBedrockTile = false 
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        if nameStr:find("bedrock") then isBedrockTile = true end
        if not nameStr:find("air") and not nameStr:find("water") and not nameStr:find("door") and not nameStr:find("bedrock") and nameStr ~= "0" then
            hasBreakable = true
        end
    end
    
    if isBedrockTile then return false end
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
                if IsTileEmpty(x, y + 1) then return x, y, "top" end
                if IsTileEmpty(x - 1, y) then return x, y, "left" end
                if IsTileEmpty(x + 1, y) then return x, y, "right" end
            end
        end
    end
    return nil, nil, nil
end

-- ========================================== --
-- [[ PATHFINDING: CEK JALUR BEDROCK ]]
-- ========================================== --
local function IsPathBlockedByBedrock(startPos, endPos)
    local distance = (startPos - endPos).Magnitude
    if distance < getgenv().GridSize then return false end
    
    -- Cek setiap setengah grid (biar gak ada yg kelewatan)
    local steps = math.ceil(distance / (getgenv().GridSize * 0.5)) 
    for i = 0, steps do
        local currentCheck = startPos:Lerp(endPos, i / steps)
        local gridX = math.floor((currentCheck.X / getgenv().GridSize) + 0.5)
        local gridY = math.floor((currentCheck.Y / getgenv().GridSize) + 0.5)
        
        if IsBedrockInGrid(gridX, gridY) then
            return true -- Ada bedrock ngehalangin!
        end
    end
    return false -- Jalur aman
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT (DINAMIS) ]]
-- ========================================== --
local function MoveToPoint(startP, endP)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local distance = (startP - endP).Magnitude
    if distance < 0.5 then return end

    local walkTime = distance / getgenv().WalkSpeed
    local steps = math.floor(walkTime * 45) 
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        if not getgenv().EnableAutoClear then break end
        local alpha = i / steps
        local currentLerp = startP:Lerp(endP, alpha)
        
        if PlayerMovement then
            PlayerMovement.Position = currentLerp
        elseif hrp then
            hrp.CFrame = CFrame.new(currentLerp)
        end
        task.wait(1/45)
    end
end

local function U_ShapeSmartWalk(startPos, targetPos)
    local safeHeight = math.max(startPos.Y, targetPos.Y) + (2 * getgenv().GridSize)
    local waypoint1 = Vector3.new(startPos.X, safeHeight, startPos.Z)
    local waypoint2 = Vector3.new(targetPos.X, safeHeight, targetPos.Z)
    
    MoveToPoint(startPos, waypoint1)
    if not getgenv().EnableAutoClear then return end
    MoveToPoint(waypoint1, waypoint2)
    if not getgenv().EnableAutoClear then return end
    MoveToPoint(waypoint2, targetPos)
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (V7 Dynamic Path)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) 
        getgenv().EnableAutoClear = v 
        SetModflyState(v)
    end 
})

SecClear:Input({ Title = "Walk Speed", Value = tostring(getgenv().WalkSpeed), Placeholder = "16", Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })
SecClear:Input({ Title = "Break Delay", Value = tostring(getgenv().ClearDelay), Placeholder = "0.15", Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end })
SecClear:Input({ Title = "Hit Count", Value = tostring(getgenv().HitCount), Placeholder = "3", Callback = function(v) getgenv().HitCount = tonumber(v) or getgenv().HitCount end })

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
                local targetX, targetY, safeSide = GetNextExposedBlock()
                
                if targetX and targetY then
                    -- Tentukan posisi berdiri
                    local standX, standY = targetX, targetY
                    if safeSide == "top" then standY = targetY + 1
                    elseif safeSide == "left" then standX = targetX - 1
                    elseif safeSide == "right" then standX = targetX + 1
                    end
                    
                    local standPos = Vector3.new(standX * getgenv().GridSize, standY * getgenv().GridSize, currZ)
                    local startPos = (PlayerMovement and PlayerMovement.Position) or hrp.Position
                    
                    -- [!] DINAMIS: Cek ada bedrock di tengah jalan atau nggak?
                    if IsPathBlockedByBedrock(startPos, standPos) then
                        U_ShapeSmartWalk(startPos, standPos) -- Lewat atas
                    else
                        MoveToPoint(startPos, standPos) -- Lurus ngebut!
                    end
                    
                    -- Pastikan berhenti kalau toggle dimatiin di tengah jalan (pakai 'continue' BUKAN 'break')
                    if not getgenv().EnableAutoClear then continue end
                    
                    if PlayerMovement then PlayerMovement.Position = standPos end
                    
                    -- Pukul
                    for i = 1, getgenv().HitCount do
                        if not getgenv().EnableAutoClear then break end -- Break ini aman karena cuma memutus loop pukulan
                        local breakTarget = Vector2.new(targetX, targetY)
                        pcall(function()
                            if RemoteBreak:IsA("RemoteEvent") then 
                                RemoteBreak:FireServer(breakTarget, tick()) 
                            else 
                                RemoteBreak:InvokeServer(breakTarget, tick()) 
                            end
                        end)
                        task.wait(getgenv().ClearDelay)
                    end
                else
                    getgenv().EnableAutoClear = false
                    SetModflyState(false) 
                    WindUI:Notify({ Title = "Selesai", Content = "World sudah bersih! (Bedrock aman)", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)
