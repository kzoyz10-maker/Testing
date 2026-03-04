local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v6.0 - U-SHAPE WALK & SMART OFFSET" 

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
                -- [!] SMART OFFSET: Kasih tau dari sisi mana blok ini bisa didekati
                if IsTileEmpty(x, y + 1) then return x, y, "top" end
                if IsTileEmpty(x - 1, y) then return x, y, "left" end
                if IsTileEmpty(x + 1, y) then return x, y, "right" end
            end
        end
    end
    return nil, nil, nil
end

-- ========================================== --
-- [[ FUNGSI MOVEMENT (U-SHAPE SAFE PATH) ]]
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

local function U_ShapeSmartWalk(targetPos)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = (PlayerMovement and PlayerMovement.Position) or hrp.Position
    if (startPos - targetPos).Magnitude < 1 then return end

    -- [!] RUTE AMAN: Naik ke ruang udara kosong -> Geser -> Turun
    local safeHeight = math.max(startPos.Y, targetPos.Y) + (2 * getgenv().GridSize)
    local waypoint1 = Vector3.new(startPos.X, safeHeight, startPos.Z)
    local waypoint2 = Vector3.new(targetPos.X, safeHeight, targetPos.Z)
    
    -- Jalan lewat rute L/U-Shape
    MoveToPoint(startPos, waypoint1) -- Terbang ke atas area aman
    if not getgenv().EnableAutoClear then return end
    MoveToPoint(waypoint1, waypoint2) -- Geser horizontal ngelewatin semua halangan
    if not getgenv().EnableAutoClear then return end
    MoveToPoint(waypoint2, targetPos) -- Turun ke target
    
    if getgenv().EnableAutoClear and PlayerMovement then 
        PlayerMovement.Position = targetPos 
    end
end

-- ========================================== --
-- [[ UI SECTION ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear (V6 Safe Path)", Box = true, Opened = true })

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
                    -- [!] TENTUKAN POSISI BERDIRI BERDASARKAN SISI YANG KOSONG
                    local standX, standY = targetX, targetY
                    if safeSide == "top" then
                        standY = targetY + 1
                    elseif safeSide == "left" then
                        standX = targetX - 1
                    elseif safeSide == "right" then
                        standX = targetX + 1
                    end
                    
                    local standPos = Vector3.new(standX * getgenv().GridSize, standY * getgenv().GridSize, currZ)
                    
                    -- Jalan lewat rute aman menghindari Bedrock
                    U_ShapeSmartWalk(standPos)
                    
                    if not getgenv().EnableAutoClear then break end
                    
                    -- Pukul
                    for i = 1, getgenv().HitCount do
                        if not getgenv().EnableAutoClear then break end
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
                    WindUI:Notify({ Title = "Selesai", Content = "World sudah bersih! (Bedrock di-bypass)", Duration = 5 })
                end
            end
        end
        task.wait(0.1)
    end
end)
