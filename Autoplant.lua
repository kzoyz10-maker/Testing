local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

TargetPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetPage.CanvasSize = UDim2.new(0, 0, 0, 0)
local listLayout = TargetPage:FindFirstChildWhichIsA("UIListLayout")
if listLayout then
    TargetPage.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TargetPage.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
    end)
end

getgenv().ScriptVersion = "Auto Farm V29 (SMART LERP WALKER)"

-- ========================================== --
-- [[ KONFIGURASI ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16     -- Kecepatan wajar, JANGAN dicepetin biar gak di-rubberband server!
getgenv().BreakDelay = 0.15  
getgenv().EnableSmartHarvest = false

getgenv().AIDictionary = getgenv().AIDictionary or {}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80) 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end
CreateToggle(TargetPage, "🚀 START V29 (SMART LERP WALKER)", "EnableSmartHarvest")

-- ========================================== --
-- [[ TAHAP 1: RADAR MAP SERVER ]]
-- ========================================== --
local function IsTileSolid(gridX, gridY)
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        if layer > 1 then
            local name = type(data) == "table" and data[1] or data
            if type(name) == "string" then
                name = string.lower(name)
                -- Filter nama yang BISA ditembus
                if string.find(name, "sapling") then continue end
                if string.find(name, "lock_area") then continue end
                if string.find(name, "dirt") then continue end
                if string.find(name, "grass") then continue end
                if string.find(name, "path") then continue end
                
                return true -- Kena halangan keras!
            end
        end
    end
    return false
end

-- ========================================== --
-- [[ TAHAP 2: BREADTH-FIRST SEARCH ]]
-- ========================================== --
local function FindPath(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    
    local queue = {{x = startX, y = startY, path = {}}}
    local visited = {}
    visited[startX .. "," .. startY] = true

    local maxSearch = 600
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

    while #queue > 0 and maxSearch > 0 do
        maxSearch = maxSearch - 1
        local current = table.remove(queue, 1)

        if current.x == targetX and current.y == targetY then
            return current.path
        end

        for _, dir in ipairs(directions) do
            local nextX = current.x + dir[1]
            local nextY = current.y + dir[2]
            local posKey = nextX .. "," .. nextY
            
            -- Pengecualian: Boleh nabrak JIKA itu adalah tujuan akhir (tanaman di atas pot)
            local isTarget = (nextX == targetX and nextY == targetY)

            if not visited[posKey] and (isTarget or not IsTileSolid(nextX, nextY)) then
                visited[posKey] = true
                local newPath = {unpack(current.path)}
                table.insert(newPath, {x = nextX, y = nextY})
                table.insert(queue, {x = nextX, y = nextY, path = newPath})
            end
        end
    end
    return nil
end

-- ========================================== --
-- [[ TAHAP 3: MOVEMENT JALAN MULUS (ANTI-RUBBERBAND) ]]
-- ========================================== --
local function SmoothWalkTo(targetPos)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local startPos = MyHitbox.Position
    local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetPos.X, targetPos.Y)).Magnitude 
    
    -- Hitung durasi perjalanan biar kecepatan = 16 walkspeed
    local duration = dist / getgenv().WalkSpeed
    if duration <= 0 then return true end
    
    local t = 0
    while t < duration do
        if not getgenv().EnableSmartHarvest then return false end
        local dt = RunService.Heartbeat:Wait()
        t = t + dt
        
        local alpha = math.clamp(t / duration, 0, 1)
        local currentPos = startPos:Lerp(targetPos, alpha)
        
        MyHitbox.CFrame = CFrame.new(currentPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = currentPos end) end
    end
    
    -- Snap akhir pas nyampe biar presisi
    MyHitbox.CFrame = CFrame.new(targetPos)
    if PlayerMovement then pcall(function() PlayerMovement.Position = targetPos end) end
    return true
end

local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.floor((MyHitbox.Position.X / getgenv().GridSize) + 0.5)
    local myGridY = math.floor((MyHitbox.Position.Y / getgenv().GridSize) + 0.5)

    if myGridX == targetX and myGridY == targetY then return true end

    local route = FindPath(myGridX, myGridY, targetX, targetY)
    
    if not route then
        print("⚠️ Buntu! Map tertutup buat ke X"..targetX.." Y"..targetY)
        return false
    end

    -- Jalan mulus nyusuri rute tanpa noclip instan
    for _, stepPos in ipairs(route) do
        if not getgenv().EnableSmartHarvest then break end
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        if not SmoothWalkTo(pos) then return false end
    end

    return true
end

-- ========================================== --
-- [[ TAHAP 4: SCAN & FARM LOGIC ]]
-- ========================================== --
local SaplingsData = {}
local function ScanWorld()
    SaplingsData = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local tileName = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        
                        if type(tileName) == "string" and string.find(string.lower(tileName), "sapling") then
                            if tileInfo and tileInfo.at then
                                table.insert(SaplingsData, {x = x, y = y, name = tileName, at = tileInfo.at})
                            end
                        end
                    end
                end
            end
        end
    end
end

local function AIBelajarWaktu(sapling)
    local sampai = MoveSmartlyTo(sapling.x, sapling.y)
    if not sampai then return false end
    
    local timer = 0
    while timer < 30 do
        local hover = workspace:FindFirstChild("HoverPart")
        if hover then
            for _, v in pairs(hover:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text ~= "" then
                    local text = string.lower(v.Text)
                    if string.find(text, "grown") or string.find(text, "harvest") then
                        local jam = tonumber(string.match(text, "(%d+)h")) or 0
                        local menit = tonumber(string.match(text, "(%d+)m")) or 0
                        local detik = tonumber(string.match(text, "(%d+)s")) or 0
                        
                        local isReady = string.find(text, "harvest") or string.find(text, "100%%")
                        local sisaWaktuLayar = (jam * 3600) + (menit * 60) + detik
                        if isReady then sisaWaktuLayar = 0 end
                        
                        local umurSekarang = workspace:GetServerTimeNow() - sapling.at
                        local totalDurasi = umurSekarang + sisaWaktuLayar
                        totalDurasi = math.floor((totalDurasi + 5) / 10) * 10
                        
                        getgenv().AIDictionary[sapling.name] = totalDurasi
                        print("🎯 AI HAFAL! " .. sapling.name .. " butuh " .. totalDurasi .. " detik!")
                        return true
                    end
                end
            end
        end
        timer = timer + 1
        task.wait(0.1)
    end
    return false
end

if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            ScanWorld()
            local targetPanen = {}

            for _, sapling in ipairs(SaplingsData) do
                if not getgenv().EnableSmartHarvest then break end
                if not getgenv().AIDictionary[sapling.name] then
                    AIBelajarWaktu(sapling)
                    task.wait(1) 
                end
                
                if getgenv().AIDictionary[sapling.name] then
                    local umur = workspace:GetServerTimeNow() - sapling.at
                    local targetMatang = getgenv().AIDictionary[sapling.name]
                    if umur >= targetMatang then
                        table.insert(targetPanen, sapling)
                    end
                end
            end
            
            for _, panen in ipairs(targetPanen) do
                if not getgenv().EnableSmartHarvest then break end
                local bisaJalan = MoveSmartlyTo(panen.x, panen.y)
                if bisaJalan then
                    task.wait(0.1)
                    pcall(function() 
                        local targetVec = Vector2.new(panen.x, panen.y)
                        if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                        else RemoteFist:InvokeServer(targetVec) end
                    end)
                    task.wait(getgenv().BreakDelay)
                end
            end
        end
        task.wait(1) 
    end
end)
