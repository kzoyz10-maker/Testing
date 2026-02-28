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

getgenv().ScriptVersion = "Auto Farm V46 + PLANT (SLOT TAS FIX) + WALKSPEED"

-- ========================================== --
-- [[ KONFIGURASI AWAL ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16     
getgenv().BreakDelay = 0.15  
getgenv().PlantDelay = 0.15

getgenv().EnableSmartHarvest = false
getgenv().EnableAutoPlant = false
getgenv().SelectedSeed = "None"
getgenv().AIDictionary = getgenv().AIDictionary or {}

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

-- ========================================== --
-- [[ SISTEM INVENTORY & SLOT ]]
-- ========================================== --
local function ScanAvailableItems()
    local items = {}; local dict = {}
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for _, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    local itemID = tostring(data.Id)
                    if not dict[itemID] then dict[itemID] = true; table.insert(items, itemID) end
                end
            end
        end
    end)
    if #items == 0 then items = {"Kosong"} end
    return items
end

-- FUNGSI BARU: Ambil Slot ID berdasarkan Item
local function GetSlotByItemID(itemID)
    local foundSlot = nil
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for slot, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and tostring(data.Id) == tostring(itemID) then
                    foundSlot = slot
                    break
                end
            end
        end
    end)
    return foundSlot
end

CreateToggle(TargetPage, "🌾 START AUTOT", "EnableSmartHarvest")
CreateToggle(TargetPage, "🌱 START AUTO PLANT", "EnableAutoPlant")
CreateDropdown(TargetPage, "🎒 CHOOSE SAPLING", "SelectedSeed", ScanAvailableItems)
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

    local maxIterations, iterations = 5000, 0
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
    task.wait(0.02) 
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
-- [[ SCANNER DATABASE WAKTU TUMBUH ]]
-- ========================================== --
local SaplingsData = {}

local function ScanWorld()
    SaplingsData = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local rawId = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        
                        local tileString = rawId
                        if type(rawId) == "number" and WorldManager.NumberToStringMap then
                            tileString = WorldManager.NumberToStringMap[rawId] or rawId
                        end
                        
                        if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") then
                            if tileInfo and tileInfo.at then
                                table.insert(SaplingsData, {x = x, y = y, name = tileString, at = tileInfo.at})
                            end
                        end
                    end
                end
            end
        end
    end
end

local function DeepFindGrowTime(tbl)
    if type(tbl) ~= "table" then return nil end
    for k, v in pairs(tbl) do
        if type(v) == "number" and type(k) == "string" then
            local kl = k:lower()
            if kl:find("grow") or kl:find("time") or kl:find("harvest") or kl:find("duration") or kl:find("age") then
                if v > 0 then return v end
            end
        elseif type(v) == "table" then
            local res = DeepFindGrowTime(v)
            if res then return res end
        end
    end
    return nil
end

local function GetExactGrowTime(saplingName)
    if getgenv().AIDictionary[saplingName] then return getgenv().AIDictionary[saplingName] end
    pcall(function()
        local baseId = string.gsub(saplingName, "_sapling", "")
        local itemData = ItemsManager.ItemsData[baseId] or ItemsManager.ItemsData[saplingName]
        if itemData then
            local foundTime = DeepFindGrowTime(itemData)
            if foundTime then getgenv().AIDictionary[saplingName] = foundTime end
        end
    end)
    return getgenv().AIDictionary[saplingName] or nil
end

local function BackupAIBelajarWaktu(sapling)
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
                        
                        local umurSekarang = os.time() - sapling.at
                        local totalDurasi = umurSekarang + sisaWaktuLayar
                        totalDurasi = math.floor((totalDurasi + 5) / 10) * 10
                        
                        getgenv().AIDictionary[sapling.name] = totalDurasi
                        return true
                    end
                end
            end
        end
        timer = timer + 1; task.wait(0.1)
    end
    return false
end

-- ========================================== --
-- [[ AUTO FARM / HARVEST LOGIC ]]
-- ========================================== --
if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end
getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            ScanWorld()
            local targetPanen = {}

            for _, sapling in ipairs(SaplingsData) do
                if not getgenv().EnableSmartHarvest then break end
                
                local targetMatang = GetExactGrowTime(sapling.name)
                
                if not targetMatang then
                    BackupAIBelajarWaktu(sapling)
                    targetMatang = getgenv().AIDictionary[sapling.name]
                end
                
                if targetMatang then
                    local umurServer1 = os.time() - sapling.at
                    local umurServer2 = workspace:GetServerTimeNow() - sapling.at
                    local umurAsli = math.max(umurServer1, umurServer2)

                    if umurAsli >= targetMatang then
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

-- ========================================== --
-- [[ AUTO PLANT LOGIC (SLOT TAS FIX) ]]
-- ========================================== --
if getgenv().KzoyzAutoPlantLoop then task.cancel(getgenv().KzoyzAutoPlantLoop) end
getgenv().KzoyzAutoPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoPlant and not getgenv().EnableSmartHarvest then 
            local targetTanam = {}
            
            -- Scan X berurutan dari 0 sampai 100 biar bot jalannya rapi dari kiri ke kanan
            for x = 0, 100 do
                local yCol = RawWorldTiles[x]
                if type(yCol) == "table" then
                    local yKeys = {}
                    for y, _ in pairs(yCol) do
                        table.insert(yKeys, y)
                    end
                    table.sort(yKeys)
                    
                    for _, y in ipairs(yKeys) do
                        if not getgenv().EnableAutoPlant then break end
                        
                        -- Cari spot KOSONG tepat di ATAS tanah
                        if IsTileSolid(x, y) and IsTileEmptyForPlant(x, y + 1) then
                            table.insert(targetTanam, {x = x, y = y + 1})
                        end
                    end
                end
            end
            
            for _, spot in ipairs(targetTanam) do
                if not getgenv().EnableAutoPlant or getgenv().EnableSmartHarvest then break end
                
                local bibit = getgenv().SelectedSeed
                if bibit ~= "Kosong" and bibit ~= "None" then 
                    
                    -- Cari NOMOR SLOT dari bibit yang dipilih
                    local seedSlot = GetSlotByItemID(bibit)
                    
                    if not seedSlot then
                        warn("⚠️ Bibit " .. tostring(bibit) .. " nggak ketemu di tas / Habis!")
                        getgenv().EnableAutoPlant = false
                        break
                    end
                    
                    local bisaJalan = MoveSmartlyTo(spot.x, spot.y)
                    if bisaJalan then
                        task.wait(0.1)
                        
                        pcall(function() 
                            local targetVec = Vector2.new(spot.x, spot.y)
                            local targetStr = tostring(spot.x) .. ", " .. tostring(spot.y)
                            
                            -- Nanam pakai RemotePlace (PlayerPlaceItem) dengan argument NOMOR SLOT tas
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
