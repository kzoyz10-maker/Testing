-- ========================================== --
-- [[ KZOYZ AUTO COLLECT DROPS & GEMS ]]
-- ========================================== --
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

getgenv().ScriptVersion = "Auto Collect V2 (Gems & Drops Only)"

-- Konfigurasi
getgenv().EnableAutoCollect = false
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ambil Data Map (Biar bot nggak nabrak)
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ UI SEDERHANA UNTUK AUTO COLLECT ]]
-- ========================================== --
function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(80, 255, 80) -- Warna Hijau
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

function CreateInput(Parent, Text, Var, DefaultValue)
    local Frame = Instance.new("Frame", Parent)
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Text; Label.TextColor3 = Color3.fromRGB(255, 255, 255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left

    local TextBox = Instance.new("TextBox", Frame)
    TextBox.Size = UDim2.new(0.3, 0, 0.7, 0)
    TextBox.Position = UDim2.new(0.65, 0, 0.15, 0)
    TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TextBox.TextColor3 = Color3.fromRGB(255, 255, 255); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 13; TextBox.Text = tostring(DefaultValue); TextBox.ClearTextOnFocus = false

    getgenv()[Var] = DefaultValue
    TextBox.FocusLost:Connect(function()
        local num = tonumber(TextBox.Text)
        if num then getgenv()[Var] = num else TextBox.Text = tostring(getgenv()[Var]) end
    end)
end

CreateToggle(TargetPage, "💎 START AUTO COLLECT (Gems & Drops)", "EnableAutoCollect")
CreateInput(TargetPage, "⚡ Lari Auto Collect (WalkSpeed)", "WalkSpeed", 16)

-- ========================================== --
-- [[ SISTEM JALAN PINTAR (ANTI MENTOK) ]]
-- ========================================== --
local BlockSolidityCache = {}
local function IsTileSolid(gridX, gridY)
    if gridX < 0 or gridX > 100 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap[rawId] or rawId) or rawId
        local nameStr = tostring(tileString):lower()
        
        if BlockSolidityCache[nameStr] ~= nil then return BlockSolidityCache[nameStr] end

        if string.find(nameStr, "bg") or string.find(nameStr, "background") or string.find(nameStr, "air") or string.find(nameStr, "water") then 
            BlockSolidityCache[nameStr] = false; continue 
        end
        
        BlockSolidityCache[nameStr] = true
        return true
    end
    return false
end

local function FindPathAStar(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    local function heuristic(x, y) return math.abs(x - targetX) + math.abs(y - targetY) end
    local openSet, closedSet, cameFrom, gScore, fScore = {}, {}, {}, {}, {}

    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0; fScore[startKey] = heuristic(startX, startY)

    local maxIterations, iterations = 2000, 0
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

    while #openSet > 0 do
        iterations = iterations + 1; if iterations > maxIterations then break end
        local current, currentIndex = openSet[1], 1
        for i = 2, #openSet do
            if fScore[openSet[i].key] < fScore[current.key] then current = openSet[i]; currentIndex = i end
        end

        if current.x == targetX and current.y == targetY then
            local path, currKey = {}, current.key
            while cameFrom[currKey] do
                local node = cameFrom[currKey]
                table.insert(path, 1, {x = current.x, y = current.y})
                current = node; currKey = node.x .. "," .. node.y
            end
            return path
        end

        table.remove(openSet, currentIndex); closedSet[current.key] = true

        for _, dir in ipairs(directions) do
            local nextX, nextY = current.x + dir[1], current.y + dir[2]
            local nextKey = nextX .. "," .. nextY
            if nextX < 0 or nextX > 100 or closedSet[nextKey] then continue end

            if not (nextX == targetX and nextY == targetY) and IsTileSolid(nextX, nextY) then closedSet[nextKey] = true; continue end

            local tentative_gScore = gScore[current.key] + 1
            if not gScore[nextKey] or tentative_gScore < gScore[nextKey] then
                cameFrom[nextKey] = current; gScore[nextKey] = tentative_gScore; fScore[nextKey] = tentative_gScore + heuristic(nextX, nextY)
                local inOpenSet = false
                for _, node in ipairs(openSet) do if node.key == nextKey then inOpenSet = true; break end end
                if not inOpenSet then table.insert(openSet, {x = nextX, y = nextY, key = nextKey}) end
            end
        end
    end
    return nil 
end

local function SmoothWalkTo(targetPos)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local startPos = MyHitbox.Position
    local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetPos.X, targetPos.Y)).Magnitude 
    local duration = dist / getgenv().WalkSpeed
    
    if duration > 0 then 
        local t = 0
        while t < duration do
            if not getgenv().EnableAutoCollect then return false end
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            local alpha = math.clamp(t / duration, 0, 1)
            local currentPos = startPos:Lerp(targetPos, alpha)
            MyHitbox.CFrame = CFrame.new(currentPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = currentPos end) end
        end
    end
    
    MyHitbox.CFrame = CFrame.new(targetPos)
    if PlayerMovement then pcall(function() PlayerMovement.Position = targetPos end) end
    task.wait(0.02) 
    return true
end

local function MoveSmartlyToDrop(targetPos)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myGridX = math.round(MyHitbox.Position.X / getgenv().GridSize)
    local myGridY = math.round(MyHitbox.Position.Y / getgenv().GridSize)
    
    local targetGridX = math.round(targetPos.X / getgenv().GridSize)
    local targetGridY = math.round(targetPos.Y / getgenv().GridSize)

    if myGridX == targetGridX and myGridY == targetGridY then
        return SmoothWalkTo(targetPos) 
    end
    
    local route = FindPathAStar(myGridX, myGridY, targetGridX, targetGridY)
    if not route then 
        return SmoothWalkTo(targetPos) 
    end

    for _, stepPos in ipairs(route) do
        if not getgenv().EnableAutoCollect then break end
        local stepVector = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, MyHitbox.Position.Z)
        if not SmoothWalkTo(stepVector) then return false end
    end
    
    return SmoothWalkTo(targetPos)
end

-- ========================================== --
-- [[ SCANNER BARANG JATUH (KHUSUS DROPS & GEMS) ]]
-- ========================================== --
local function GetNearestDrops()
    local drops = {}
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return drops end

    -- Hanya fokus ke folder Drops dan Gems sesuai target
    local dropContainers = {
        workspace:FindFirstChild("Drops"),
        workspace:FindFirstChild("Gems")
    }

    for _, container in ipairs(dropContainers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                local pos = nil
                if item:IsA("Model") and item.PrimaryPart then
                    pos = item.PrimaryPart.Position
                elseif item:IsA("BasePart") then
                    pos = item.Position
                end
                
                if pos then
                    local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude
                    table.insert(drops, {instance = item, position = pos, dist = distance})
                end
            end
        end
    end

    -- Urutkan dari yang paling DEKAT dengan player
    table.sort(drops, function(a, b) return a.dist < b.dist end)
    return drops
end

-- ========================================== --
-- [[ LOOP AUTO COLLECT ]]
-- ========================================== --
if getgenv().KzoyzAutoCollectLoop then task.cancel(getgenv().KzoyzAutoCollectLoop) end
getgenv().KzoyzAutoCollectLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoCollect then
            local availableDrops = GetNearestDrops()
            
            if #availableDrops > 0 then
                for _, drop in ipairs(availableDrops) do
                    if not getgenv().EnableAutoCollect then break end
                    
                    if drop.instance and drop.instance.Parent then
                        MoveSmartlyToDrop(drop.position)
                        task.wait(0.1) -- Jeda bentar biar barangnya masuk tas
                    end
                end
            end
        end
        task.wait(0.5) 
    end
end)
