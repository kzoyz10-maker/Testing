-- ========================================== --
-- [[ KZOYZ AUTO COLLECT + PRO ESP + GROWSCAN ]]
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

getgenv().ScriptVersion = "Collect V6 + Bug Fixes"
getgenv().EnableAutoCollect = false
getgenv().EnableDropESP = false
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16
getgenv().AIDictionary = getgenv().AIDictionary or {}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ BIKIN UI MENU ]]
-- ========================================== --
function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

function CreateInput(Parent, Text, Var, DefaultValue)
    local Frame = Instance.new("Frame", Parent); Frame.Size = UDim2.new(1, -10, 0, 40); Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    local Label = Instance.new("TextLabel", Frame); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.Text = Text; Label.TextColor3 = Color3.fromRGB(255, 255, 255); Label.Font = Enum.Font.GothamBold; Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left
    local TextBox = Instance.new("TextBox", Frame); TextBox.Size = UDim2.new(0.3, 0, 0.7, 0); TextBox.Position = UDim2.new(0.65, 0, 0.15, 0); TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TextBox.TextColor3 = Color3.fromRGB(255, 255, 255); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 13; TextBox.Text = tostring(DefaultValue); TextBox.ClearTextOnFocus = false
    getgenv()[Var] = DefaultValue
    TextBox.FocusLost:Connect(function() local num = tonumber(TextBox.Text); if num then getgenv()[Var] = num else TextBox.Text = tostring(getgenv()[Var]) end end)
end

function CreateButton(Parent, Text, Callback)
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200); Btn.Size = UDim2.new(1, -10, 0, 40); Btn.Text = "🔍 " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13;
    Btn.MouseButton1Click:Connect(Callback)
end

CreateToggle(TargetPage, "💎 START AUTO COLLECT (Drops & Gems)", "EnableAutoCollect")
CreateToggle(TargetPage, "🎯 TRACER ESP (Garis FPS Style)", "EnableDropESP")
CreateInput(TargetPage, "⚡ Lari Auto Collect (WalkSpeed)", "WalkSpeed", 16)

-- ========================================== --
-- [[ GROWSCAN MODAL ]]
-- ========================================== --
local function GetExactGrowTime(saplingName)
    if getgenv().AIDictionary[saplingName] then return getgenv().AIDictionary[saplingName] end
    pcall(function()
        local baseId = string.gsub(saplingName, "_sapling", "")
        local itemData = ItemsManager.ItemsData[baseId] or ItemsManager.ItemsData[saplingName]
        if itemData then
            local foundTime = nil
            for k, v in pairs(itemData) do if type(v) == "number" and (k:lower():find("grow") or k:lower():find("time")) then foundTime = v; break end end
            if foundTime then getgenv().AIDictionary[saplingName] = foundTime end
        end
    end)
    return getgenv().AIDictionary[saplingName] or 300 
end

local function OpenGrowscanModal()
    if CoreGui:FindFirstChild("KzoyzGrowscan") then CoreGui.KzoyzGrowscan:Destroy() end

    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "KzoyzGrowscan"
    
    local mainFrame = Instance.new("Frame", gui)
    mainFrame.Size = UDim2.new(0, 350, 0, 450); mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35); mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
    
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundColor3 = Color3.fromRGB(25, 25, 25); title.Text = "📊 WORLD GROWSCAN"; title.TextColor3 = Color3.fromRGB(255, 215, 0); title.Font = Enum.Font.GothamBold; title.TextSize = 16
    
    local closeBtn = Instance.new("TextButton", title)
    closeBtn.Size = UDim2.new(0, 40, 1, 0); closeBtn.Position = UDim2.new(1, -40, 0, 0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 16
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45); scroll.ScrollBarThickness = 4
    local uiList = Instance.new("UIListLayout", scroll); uiList.Padding = UDim.new(0, 5)

    local plantStats = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local rawId = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap[rawId] or rawId) or rawId
                        
                        if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") and tileInfo and tileInfo.at then
                            local name = tostring(tileString)
                            if not plantStats[name] then plantStats[name] = { total = 0, ready = 0, growing = 0 } end
                            plantStats[name].total = plantStats[name].total + 1
                            
                            local age = workspace:GetServerTimeNow() - tileInfo.at
                            if age >= GetExactGrowTime(name) then plantStats[name].ready = plantStats[name].ready + 1 else plantStats[name].growing = plantStats[name].growing + 1 end
                        end
                    end
                end
            end
        end
    end

    local totalY = 0
    for plantName, stat in pairs(plantStats) do
        local frame = Instance.new("Frame", scroll); frame.Size = UDim2.new(1, 0, 0, 60); frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        local lblName = Instance.new("TextLabel", frame); lblName.Size = UDim2.new(1, -10, 0, 20); lblName.Position = UDim2.new(0, 10, 0, 5); lblName.BackgroundTransparency = 1; lblName.Text = "🌱 " .. string.upper(string.gsub(plantName, "_sapling", "")); lblName.TextColor3 = Color3.fromRGB(255, 255, 255); lblName.Font = Enum.Font.GothamBold; lblName.TextXAlignment = Enum.TextXAlignment.Left; lblName.TextSize = 14
        local lblStat = Instance.new("TextLabel", frame); lblStat.Size = UDim2.new(1, -10, 0, 20); lblStat.Position = UDim2.new(0, 10, 0, 30); lblStat.BackgroundTransparency = 1; lblStat.Text = "Total: " .. stat.total .. " | ✅ Ready: " .. stat.ready .. " | ⏳ Growing: " .. stat.growing; lblStat.TextColor3 = Color3.fromRGB(200, 200, 200); lblStat.Font = Enum.Font.Gotham; lblStat.TextXAlignment = Enum.TextXAlignment.Left; lblStat.TextSize = 12
        totalY = totalY + 65
    end

    local sep = Instance.new("TextLabel", scroll)
    sep.Size = UDim2.new(1, 0, 0, 20); sep.BackgroundTransparency = 1
    sep.Text = "--------------------------------------------------"; sep.TextColor3 = Color3.fromRGB(150, 150, 150); sep.Font = Enum.Font.GothamBold; sep.TextSize = 14
    totalY = totalY + 25

    local dropsFolder = workspace:FindFirstChild("Drops")
    local gemsFolder = workspace:FindFirstChild("Gems")
    local totalGems = gemsFolder and #gemsFolder:GetChildren() or 0
    
    local dropStats = {}
    local totalDrops = 0
    if dropsFolder then
        for _, item in ipairs(dropsFolder:GetChildren()) do
            local name = item.Name
            if name then
                dropStats[name] = (dropStats[name] or 0) + 1
                totalDrops = totalDrops + 1
            end
        end
    end

    local dropTitle = Instance.new("TextLabel", scroll); dropTitle.Size = UDim2.new(1, -10, 0, 20); dropTitle.Position = UDim2.new(0, 10, 0, 0); dropTitle.BackgroundTransparency = 1; dropTitle.Text = "📦 BARANG TERGELETAK (Drops: " .. totalDrops .. " | 💎 Gems: " .. totalGems .. ")"; dropTitle.TextColor3 = Color3.fromRGB(100, 200, 255); dropTitle.Font = Enum.Font.GothamBold; dropTitle.TextXAlignment = Enum.TextXAlignment.Left; dropTitle.TextSize = 13
    totalY = totalY + 25

    for dName, dCount in pairs(dropStats) do
        local dFrame = Instance.new("Frame", scroll); dFrame.Size = UDim2.new(1, 0, 0, 30); dFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
        local dLbl = Instance.new("TextLabel", dFrame); dLbl.Size = UDim2.new(1, -10, 1, 0); dLbl.Position = UDim2.new(0, 10, 0, 0); dLbl.BackgroundTransparency = 1; dLbl.Text = "   🔹 " .. dName .. " : " .. dCount .. "x"; dLbl.TextColor3 = Color3.fromRGB(255, 255, 255); dLbl.Font = Enum.Font.Gotham; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextSize = 13
        totalY = totalY + 35
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, totalY)
end

CreateButton(TargetPage, "Buka Modal Growscan", OpenGrowscanModal)

-- ========================================== --
-- [[ PATHFINDING (A-STAR) PINTAR KEMBALI ]]
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
            MyHitbox.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
            if PlayerMovement then pcall(function() PlayerMovement.Position = startPos:Lerp(targetPos, alpha) end) end
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

    if myGridX == targetGridX and myGridY == targetGridY then return SmoothWalkTo(targetPos) end
    
    local route = FindPathAStar(myGridX, myGridY, targetGridX, targetGridY)
    if not route then return SmoothWalkTo(targetPos) end

    for _, stepPos in ipairs(route) do
        if not getgenv().EnableAutoCollect then break end
        local stepVector = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, MyHitbox.Position.Z)
        if not SmoothWalkTo(stepVector) then return false end
    end
    return SmoothWalkTo(targetPos)
end

if getgenv().KzoyzAutoCollectLoop then task.cancel(getgenv().KzoyzAutoCollectLoop) end
getgenv().KzoyzAutoCollectLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoCollect then
            local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
            if MyHitbox then
                local drops = {}
                local dropContainers = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
                for _, container in ipairs(dropContainers) do
                    if container then
                        for _, item in ipairs(container:GetChildren()) do
                            local pos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
                            if pos then table.insert(drops, {instance = item, position = pos, dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude}) end
                        end
                    end
                end
                table.sort(drops, function(a, b) return a.dist < b.dist end)
                
                if #drops > 0 and drops[1].instance.Parent then
                    MoveSmartlyToDrop(drops[1].position)
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.2) 
    end
end)

-- ========================================== --
-- [[ TRACER ESP (GARIS JAUH) LOGIC ]]
-- ========================================== --
local ESPGui = CoreGui:FindFirstChild("KzoyzESPGui")
if not ESPGui then ESPGui = Instance.new("ScreenGui", CoreGui); ESPGui.Name = "KzoyzESPGui"; ESPGui.IgnoreGuiInset = true end
ESPGui:ClearAllChildren()

local TracerLines = {}

local function GetLineFrame(item)
    if not TracerLines[item] then
        local line = Instance.new("Frame", ESPGui)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BorderSizePixel = 0
        line.BackgroundColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 255, 0)
        TracerLines[item] = line
    end
    return TracerLines[item]
end

if getgenv().KzoyzESPLoop then getgenv().KzoyzESPLoop:Disconnect() end
getgenv().KzoyzESPLoop = RunService.RenderStepped:Connect(function()
    pcall(function() -- Tambah pcall biar ga crash seluruh game kalau error
        if not getgenv().EnableDropESP then
            ESPGui:ClearAllChildren(); TracerLines = {}
            return
        end

        local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
        if not MyHitbox then return end

        local activeItems = {}
        local dropContainers = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
        
        for _, container in ipairs(dropContainers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    activeItems[item] = true
                    local targetPos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
                    
                    if targetPos then
                        local espUI = item:FindFirstChild("KzoyzTextESP")
                        local dist = math.floor((Vector2.new(targetPos.X, targetPos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude)
                        if not espUI then
                            espUI = Instance.new("BillboardGui", item)
                            espUI.Name = "KzoyzTextESP"
                            espUI.AlwaysOnTop = true; espUI.Size = UDim2.new(0, 100, 0, 30); espUI.StudsOffset = Vector3.new(0, 2, 0)
                            local txt = Instance.new("TextLabel", espUI)
                            txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextStrokeTransparency = 0.2
                            txt.TextColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 255, 100)
                            txt.Font = Enum.Font.GothamBold; txt.TextSize = 10
                        end
                        espUI.TextLabel.Text = (item.Parent.Name == "Gems" and "💎 Gem" or item.Name) .. "\n[" .. dist .. "m]"

                        local line = GetLineFrame(item)
                        -- FIX: Ambil koordinat Screen + kedalaman (Z) secara terpisah
                        local startScreen = Camera:WorldToViewportPoint(MyHitbox.Position)
                        local endScreen = Camera:WorldToViewportPoint(targetPos)

                        -- Cek Z-Depth aja buat tau targetnya ada di depan mata/engga
                        if endScreen.Z > 0 then
                            line.Visible = true
                            local p1 = Vector2.new(startScreen.X, startScreen.Y)
                            local p2 = Vector2.new(endScreen.X, endScreen.Y)
                            
                            local lineLength = (p1 - p2).Magnitude
                            line.Size = UDim2.new(0, lineLength, 0, 1.5)
                            line.Position = UDim2.new(0, (p1.X + p2.X) / 2, 0, (p1.Y + p2.Y) / 2)
                            line.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end

        for item, line in pairs(TracerLines) do
            if not activeItems[item] then
                line:Destroy(); TracerLines[item] = nil
                if item and item:FindFirstChild("KzoyzTextESP") then item.KzoyzTextESP:Destroy() end
            end
        end
    end)
end)
