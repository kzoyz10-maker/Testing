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

getgenv().ScriptVersion = "Auto Farm V59 (BRUTE FORCE + SWEEP BACK 100-0)"

-- ========================================== --
-- [[ KONFIGURASI AWAL ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16     
getgenv().BreakDelay = 0.15  
getgenv().PlantDelay = 0.15

getgenv().EnableSmartHarvest = false
getgenv().EnableAutoPlant = false
getgenv().SelectedSeed = "Kosong"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- REMOTES
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem") 

-- MANAGERS
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

-- ========================================== --
-- [[ SISTEM INVENTORY TRANSLATOR ]]
-- ========================================== --
getgenv().InventoryCacheNameMap = {}

local function GetItemName(rawId)
    if type(rawId) == "string" then return rawId end
    if WorldManager and WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] then
        return WorldManager.NumberToStringMap[rawId]
    end
    if ItemsManager and ItemsManager.ItemsData and ItemsManager.ItemsData[rawId] then
        local data = ItemsManager.ItemsData[rawId]
        if type(data) == "table" and data.Name then return data.Name end
    end
    return tostring(rawId)
end

local function ScanAvailableItems()
    local items = {}
    local dict = {}
    getgenv().InventoryCacheNameMap = {} 
    
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for slotIndex, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    if not data.Amount or data.Amount > 0 then
                        local realId = data.Id
                        local itemName = GetItemName(realId)
                        
                        if not dict[itemName] then 
                            dict[itemName] = true
                            table.insert(items, itemName)
                            getgenv().InventoryCacheNameMap[itemName] = realId
                        end
                    end
                end
            end
        end
    end)
    
    if #items == 0 then table.insert(items, "Kosong"); getgenv().InventoryCacheNameMap["Kosong"] = nil end
    table.sort(items)
    return items
end

local function GetSlotByItemName(targetName)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    local targetID = getgenv().InventoryCacheNameMap[targetName] or targetName
    
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
end

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
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80) 
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

function CreateDropdown(Parent, Text, Var, GetOptionsFunc)
    local Container = Instance.new("Frame", Parent)
    Container.Size = UDim2.new(1, -10, 0, 40)
    Container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Container.ClipsDescendants = true
    
    local MainBtn = Instance.new("TextButton", Container)
    MainBtn.Size = UDim2.new(1, 0, 0, 40)
    MainBtn.BackgroundTransparency = 1
    MainBtn.Text = "  " .. Text .. ": " .. tostring(getgenv()[Var])
    MainBtn.TextColor3 = Color3.fromRGB(255, 215, 0) 
    MainBtn.Font = Enum.Font.GothamBold; MainBtn.TextSize = 13; MainBtn.TextXAlignment = Enum.TextXAlignment.Left

    local Scroll = Instance.new("ScrollingFrame", Container)
    Scroll.Size = UDim2.new(1, 0, 1, -40); Scroll.Position = UDim2.new(0, 0, 0, 40)
    Scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 35); Scroll.ScrollBarThickness = 4
    local UIList = Instance.new("UIListLayout", Scroll)
    
    local isOpen = false
    MainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local options = GetOptionsFunc()
            for _, child in ipairs(Scroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            local ySize = 0
            for _, opt in ipairs(options) do
                local btn = Instance.new("TextButton", Scroll)
                btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                btn.Text = "  " .. tostring(opt); btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                btn.Font = Enum.Font.Gotham; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left
                ySize = ySize + 30
                
                btn.MouseButton1Click:Connect(function()
                    getgenv()[Var] = opt
                    MainBtn.Text = "  " .. Text .. ": " .. tostring(opt)
                    Container.Size = UDim2.new(1, -10, 0, 40)
                    isOpen = false
                end)
            end
            Scroll.CanvasSize = UDim2.new(0, 0, 0, ySize)
            Container.Size = UDim2.new(1, -10, 0, 140) 
        else
            Container.Size = UDim2.new(1, -10, 0, 40) 
        end
    end)
end

CreateToggle(TargetPage, "🌾 START AUTO HARVEST", "EnableSmartHarvest")
CreateToggle(TargetPage, "🌱 START AUTO PLANT", "EnableAutoPlant")
CreateDropdown(TargetPage, " CHOOSE SAPLING", "SelectedSeed", ScanAvailableItems)
CreateInput(TargetPage, "⚡ Walk Speed", "WalkSpeed", 16)
CreateInput(TargetPage, "🔨 Harvest Delay", "BreakDelay", 0.15)
CreateInput(TargetPage, "🌿 Plant Delay", "PlantDelay", 0.15)

-- ========================================== --
-- [[ RADAR INVERTED (ANTI MENTOK) ]]
-- ========================================== --
local BlockSolidityCache = {}

local function IsTileSolid(gridX, gridY)
    if gridX < 0 or gridX > 100 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then
            tileString = WorldManager.NumberToStringMap[rawId] or rawId
        end
        local nameStr = tostring(tileString):lower()
        
        if BlockSolidityCache[nameStr] ~= nil then 
            if BlockSolidityCache[nameStr] == true then return true end
            continue 
        end

        if string.find(nameStr, "bg") or string.find(nameStr, "background") or string.find(nameStr, "sapling") or string.find(nameStr, "door") or string.find(nameStr, "seed") or string.find(nameStr, "air") or string.find(nameStr, "water") then 
            BlockSolidityCache[nameStr] = false
            continue 
        end
        
        BlockSolidityCache[nameStr] = true
        return true
    end
    return false
end

local function IsTileEmptyForPlant(gridX, gridY)
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then
            tileString = WorldManager.NumberToStringMap[rawId] or rawId
        end
        local nameStr = tostring(tileString):lower()
        if not string.find(nameStr, "bg") and not string.find(nameStr, "background") and not string.find(nameStr, "air") and not string.find(nameStr, "water") then 
            return false
        end
    end
    return true
end

-- ========================================== --
-- [[ A-STAR & MOVEMENT ]]
-- ========================================== --
local function FindPathAStar(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    local function heuristic(x, y) return math.abs(x - targetX) + math.abs(y - targetY) end
    local openSet, closedSet, cameFrom, gScore, fScore = {}, {}, {}, {}, {}

    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0; fScore[startKey] = heuristic(startX, startY)

    local maxIterations, iterations = 3000, 0
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

            local isTarget = (nextX == targetX and nextY == targetY)
            if not isTarget and IsTileSolid(nextX, nextY) then closedSet[nextKey] = true; continue end

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
            if not getgenv().EnableSmartHarvest and not getgenv().EnableAutoPlant then return false end
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
    task.wait(0.01) 
    return true
end

local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.round(MyHitbox.Position.X / getgenv().GridSize)
    local myGridY = math.round(MyHitbox.Position.Y / getgenv().GridSize)

    if myGridX == targetX and myGridY == targetY then return true end
    
    local route = FindPathAStar(myGridX, myGridY, targetX, targetY)
    if not route then return false end

    for _, stepPos in ipairs(route) do
        if not getgenv().EnableSmartHarvest and not getgenv().EnableAutoPlant then break end
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        if not SmoothWalkTo(pos) then return false end
    end
    return true
end

-- ========================================== --
-- [[ AUTO HARVEST LOGIC (TYPEWRITER + SWEEP BACK) ]]
-- ========================================== --
if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end
getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            local SaplingsData = {}
            for x, yCol in pairs(RawWorldTiles) do
                if type(yCol) == "table" then
                    for y, layers in pairs(yCol) do
                        if type(layers) == "table" then
                            for layer, data in pairs(layers) do
                                local rawId = type(data) == "table" and data[1] or data
                                local tileString = rawId
                                
                                if type(rawId) == "number" and WorldManager.NumberToStringMap then
                                    tileString = WorldManager.NumberToStringMap[rawId] or rawId
                                end
                                
                                if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") then
                                    table.insert(SaplingsData, {x = x, y = y})
                                end
                            end
                        end
                    end
                end
            end
            
            -- SORTIR UBAH TOTAL: Selalu dari X = 0 sampai ke X = 100 buat tiap baris
            table.sort(SaplingsData, function(a, b)
                if a.y == b.y then
                    return a.x < b.x -- Ga pake zigzag, selalu kiri ke kanan!
                end
                return a.y < b.y 
            end)

            -- Langsung samperin dan gebuk satu-satu
            for i, sapling in ipairs(SaplingsData) do
                if not getgenv().EnableSmartHarvest then break end
                local bisaJalan = MoveSmartlyTo(sapling.x, sapling.y)
                
                if bisaJalan then
                    task.wait(0.05)
                    pcall(function() 
                        local targetVec = Vector2.new(sapling.x, sapling.y)
                        if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                        else RemoteFist:InvokeServer(targetVec) end
                    end)
                    task.wait(getgenv().BreakDelay)
                    
                    -- CEK APAKAH INI TANAMAN TERAKHIR DI BARIS (Y) INI
                    local nextSapling = SaplingsData[i + 1]
                    if not nextSapling or nextSapling.y ~= sapling.y then
                        -- TAHAP 1: Maju +1 ke depan buat ambil rontokan terakhir
                        MoveSmartlyTo(sapling.x + 1, sapling.y)
                        task.wait(0.1)
                        
                        -- TAHAP 2: Lari lurus balik ke X=0 buat SWEEP BERSIH sisa dropan!
                        MoveSmartlyTo(0, sapling.y)
                        task.wait(0.1)
                    end
                end
            end
        end
        task.wait(1) 
    end
end)

-- ========================================== --
-- [[ AUTO PLANT LOGIC ]]
-- ========================================== --
if getgenv().KzoyzAutoPlantLoop then task.cancel(getgenv().KzoyzAutoPlantLoop) end
getgenv().KzoyzAutoPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoPlant and not getgenv().EnableSmartHarvest then 
            local tempList = {}
            for x = 0, 100 do
                local yCol = RawWorldTiles[x]
                if type(yCol) == "table" then
                    for y, _ in pairs(yCol) do
                        if IsTileSolid(x, y) and IsTileEmptyForPlant(x, y + 1) then
                            table.insert(tempList, {x = x, y = y + 1})
                        end
                    end
                end
            end
            
            table.sort(tempList, function(a, b)
                if a.y == b.y then
                    if a.y % 2 == 0 then return a.x < b.x else return a.x > b.x end
                end
                return a.y < b.y 
            end)

            for _, spot in ipairs(tempList) do
                if not getgenv().EnableAutoPlant or getgenv().EnableSmartHarvest then break end
                
                local bibit = getgenv().SelectedSeed
                if bibit ~= "Kosong" and bibit ~= "None" then 
                    
                    local seedSlot = GetSlotByItemName(bibit)
                    if not seedSlot then
                        warn("⚠️ Bibit " .. tostring(bibit) .. " habis!")
                        getgenv().EnableAutoPlant = false
                        break
                    end
                    
                    local bisaJalan = MoveSmartlyTo(spot.x, spot.y)
                    if bisaJalan then
                        task.wait(0.05)
                        pcall(function() 
                            local targetVec = Vector2.new(spot.x, spot.y)
                            local targetStr = tostring(spot.x) .. ", " .. tostring(spot.y)
                            if RemotePlace:IsA("RemoteEvent") then 
                                RemotePlace:FireServer(targetVec, seedSlot) 
                                RemotePlace:FireServer(targetStr, seedSlot) 
                            else 
                                RemotePlace:InvokeServer(targetVec, seedSlot) 
                            end
                        end)
                        task.wait(getgenv().PlantDelay)
                    end
                end
            end
        end
        task.wait(1.5) 
    end
end)
