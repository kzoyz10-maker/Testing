local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

getgenv().ScriptVersion = "Pabrik v1.0 - SWEEP PER-BARIS & STRICT THRESHOLD" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().WalkSpeed = 16     
getgenv().PlaceDelay = 0.15  
getgenv().DropDelay = 0.5      
getgenv().BreakDelay = 0.15 
getgenv().HitCount = 3    

getgenv().EnablePabrik = false
getgenv().OnlyCollectSapling = true
getgenv().PabrikStartX = 0
getgenv().PabrikEndX = 100
getgenv().PabrikStartY = 0
getgenv().PabrikEndY = 100

getgenv().BreakPosX = 0; getgenv().BreakPosY = 0
getgenv().DropPosX = 0; getgenv().DropPosY = 0

getgenv().BlockThreshold = 20 
getgenv().KeepSeedAmt = 20    

getgenv().SelectedSeed = "Kosong"
getgenv().SelectedBlock = "Kosong" 

getgenv().AIDictionary = getgenv().AIDictionary or {}
getgenv().IsGhosting = false
getgenv().HoldCFrame = nil
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser") 
local RunService = game:GetService("RunService")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem") 

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local InventoryMod, UIManager, PlayerMovement
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

if getgenv().KzoyzHeartbeatPabrik then getgenv().KzoyzHeartbeatPabrik:Disconnect(); getgenv().KzoyzHeartbeatPabrik = nil end

getgenv().KzoyzHeartbeatPabrik = RunService.Heartbeat:Connect(function()
    if getgenv().IsGhosting then
        if getgenv().HoldCFrame then
            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") then 
                char.HumanoidRootPart.CFrame = getgenv().HoldCFrame 
            end
        end
        if PlayerMovement then
            pcall(function()
                PlayerMovement.VelocityY = 0; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityZ = 0
                PlayerMovement.Grounded = true; PlayerMovement.Jumping = false
            end)
        end
    end
end)

-- ========================================== --
-- [[ INVENTORY TRANSLATOR ]]
-- ========================================== --
getgenv().InventoryCacheNameMap = {}

local function GetItemName(rawId)
    if type(rawId) == "string" then return rawId end
    if WorldManager and WorldManager.NumberToStringMap and WorldManager.NumberToStringMap[rawId] then return WorldManager.NumberToStringMap[rawId] end
    if ItemsManager and ItemsManager.ItemsData and ItemsManager.ItemsData[rawId] then
        local data = ItemsManager.ItemsData[rawId]
        if type(data) == "table" and data.Name then return data.Name end
    end
    return tostring(rawId)
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

local function GetItemAmountByItemName(targetName)
    local total = 0
    if not InventoryMod or not InventoryMod.Stacks then return total end
    local targetID = getgenv().InventoryCacheNameMap[targetName] or targetName
    for _, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            total = total + (data.Amount or 1)
        end
    end
    return total
end

local function ScanAvailableItems()
    local items = {}; local dict = {}
    getgenv().InventoryCacheNameMap = {}
    pcall(function()
        if InventoryMod and InventoryMod.Stacks then
            for _, data in pairs(InventoryMod.Stacks) do
                if type(data) == "table" and data.Id then
                    if not data.Amount or data.Amount > 0 then
                        local realId = data.Id
                        local itemName = GetItemName(realId)
                        if not dict[itemName] then 
                            dict[itemName] = true; table.insert(items, itemName)
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

-- ========================================== --
-- [[ RADAR INVERTED & A-STAR ]]
-- ========================================== --
local BlockSolidityCache = {}
local function IsTileSolid(gridX, gridY)
    if gridX < 0 or gridX > 100 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
        local nameStr = tostring(tileString):lower()
        if BlockSolidityCache[nameStr] ~= nil then 
            if BlockSolidityCache[nameStr] == true then return true end
        else
            if string.find(nameStr, "bg") or string.find(nameStr, "background") or string.find(nameStr, "sapling") or string.find(nameStr, "door") or string.find(nameStr, "seed") or string.find(nameStr, "air") or string.find(nameStr, "water") then 
                BlockSolidityCache[nameStr] = false
            else
                BlockSolidityCache[nameStr] = true; return true
            end
        end
    end
    return false
end

local function IsTileEmptyForPlant(gridX, gridY)
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return true end
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
        local nameStr = tostring(tileString):lower()
        if not string.find(nameStr, "bg") and not string.find(nameStr, "background") and not string.find(nameStr, "air") and not string.find(nameStr, "water") then return false end
    end
    return true
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
        for i = 2, #openSet do if fScore[openSet[i].key] < fScore[current.key] then current = openSet[i]; currentIndex = i end end

        if current.x == targetX and current.y == targetY then
            local path, currKey = {}, current.key
            while cameFrom[currKey] do
                local node = cameFrom[currKey]; table.insert(path, 1, {x = current.x, y = current.y}); current = node; currKey = node.x .. "," .. node.y
            end
            return path
        end
        table.remove(openSet, currentIndex); closedSet[current.key] = true
        for _, dir in ipairs(directions) do
            local nextX, nextY = current.x + dir[1], current.y + dir[2]
            local nextKey = nextX .. "," .. nextY
            if nextX >= 0 and nextX <= 100 and not closedSet[nextKey] then
                local isTarget = (nextX == targetX and nextY == targetY)
                if isTarget or not IsTileSolid(nextX, nextY) then
                    local tentative_gScore = gScore[current.key] + 1
                    if not gScore[nextKey] or tentative_gScore < gScore[nextKey] then
                        cameFrom[nextKey] = current; gScore[nextKey] = tentative_gScore; fScore[nextKey] = tentative_gScore + heuristic(nextX, nextY)
                        local inOpenSet = false
                        for _, node in ipairs(openSet) do if node.key == nextKey then inOpenSet = true; break end end
                        if not inOpenSet then table.insert(openSet, {x = nextX, y = nextY, key = nextKey}) end
                    end
                else closedSet[nextKey] = true end
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
            if not getgenv().EnablePabrik then return false end
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
        if not getgenv().EnablePabrik then break end
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        if not SmoothWalkTo(pos) then return false end
    end
    return true
end

-- ========================================== --
-- [[ SMART AI HARVEST WAKTU ]]
-- ========================================== --
local function DeepFindGrowTime(tbl)
    if type(tbl) ~= "table" then return nil end
    for k, v in pairs(tbl) do
        if type(v) == "number" and type(k) == "string" then
            local kl = k:lower()
            if kl:find("grow") or kl:find("time") or kl:find("harvest") or kl:find("duration") or kl:find("age") then if v > 0 then return v end end
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
    while timer < 20 do
        if not getgenv().EnablePabrik then return false end
        local hover = workspace:FindFirstChild("HoverPart")
        if hover then
            for _, v in pairs(hover:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text ~= "" then
                    local text = string.lower(v.Text)
                    if string.find(text, "grown") or string.find(text, "harvest") or string.find(text, "100%%") then
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
-- [[ GHOST COLLECT & UTILS ]]
-- ========================================== --
local function CheckDropsType(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local hasSapling = false; local hasAny = false
    
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") then
                    local firstPart = obj:FindFirstChildWhichIsA("BasePart"); if firstPart then pos = firstPart.Position end
                end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    if dX == TargetGridX and dY == TargetGridY then
                        hasAny = true
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do
                            if type(attrValue) == "string" and (string.find(string.lower(attrValue), "sapling") or string.find(string.lower(attrValue), "seed")) then isSapling = true; break end
                        end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and (string.find(string.lower(child.Value), "sapling") or string.find(string.lower(child.Value), "seed")) then isSapling = true; break end
                                for _, attrValue in pairs(child:GetAttributes()) do
                                    if type(attrValue) == "string" and (string.find(string.lower(attrValue), "sapling") or string.find(string.lower(attrValue), "seed")) then isSapling = true; break end
                                end
                                if isSapling then break end
                            end
                        end
                        if isSapling then hasSapling = true end
                    end
                end
            end
        end
    end
    return hasAny, hasSapling
end

local function TrueGhostCollect(targetX, targetY, collectSaplingOnly)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    
    local ExactHrpCF = hrp and hrp.CFrame
    local ExactHitboxCF = MyHitbox and MyHitbox.CFrame
    local ExactPMPos = nil
    if PlayerMovement then pcall(function() ExactPMPos = PlayerMovement.Position end) end

    if hrp then getgenv().HoldCFrame = ExactHrpCF; hrp.Anchored = true; getgenv().IsGhosting = true end
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        local tracks = animator and animator:GetPlayingAnimationTracks() or hum:GetPlayingAnimationTracks()
        for _, track in ipairs(tracks) do track:Stop(0) end
    end
    
    MoveSmartlyTo(targetX, targetY)
    
    local waitTimeout = 0
    while waitTimeout < 15 and getgenv().EnablePabrik do
        local anyDrop, sapDrop = CheckDropsType(targetX, targetY)
        if collectSaplingOnly then if not sapDrop then break end else if not anyDrop then break end end
        task.wait(0.1); waitTimeout = waitTimeout + 1
    end
    
    task.wait(0.1)
    MoveSmartlyTo(getgenv().BreakPosX, getgenv().BreakPosY) 
    
    if hrp and ExactHrpCF then 
        hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
        hrp.CFrame = ExactHrpCF
        if PlayerMovement and ExactPMPos then 
            pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true end) 
        end
        RunService.Heartbeat:Wait(); hrp.Anchored = false 
        for _ = 1, 2 do if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end; RunService.Heartbeat:Wait() end
    end
    getgenv().IsGhosting = false 
end

local function DropItemLogic(targetName, dropAmount)
    local slot = GetSlotByItemName(targetName)
    if not slot then return false end
    local dropRemote = RS:WaitForChild("Remotes"):FindFirstChild("PlayerDrop") or RS:WaitForChild("Remotes"):FindFirstChild("PlayerDropItem")
    local promptRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):FindFirstChild("UIPromptEvent")
    if dropRemote and promptRemote then
        pcall(function() dropRemote:FireServer(slot) end); task.wait(0.2) 
        pcall(function() promptRemote:FireServer({ ButtonAction = "drp", Inputs = { amt = tostring(dropAmount) } }) end); task.wait(0.1)
        pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
        return true
    end
    return false
end

-- ========================================== --
-- [[ UI MAKER ]]
-- ========================================== --
for _, v in pairs(TargetPage:GetChildren()) do if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then v:Destroy() end end

local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }
local TabNav = Instance.new("Frame", TargetPage); TabNav.Size = UDim2.new(1, 0, 0, 35); TabNav.BackgroundTransparency = 1; TabNav.ZIndex = 2
local TabPabrikBtn = Instance.new("TextButton", TabNav); TabPabrikBtn.Size = UDim2.new(0.49, 0, 1, 0); TabPabrikBtn.BackgroundColor3 = Theme.Purple; TabPabrikBtn.Text = "Pabrik Config"; TabPabrikBtn.TextColor3 = Color3.new(1,1,1); TabPabrikBtn.Font = Enum.Font.GothamBold; TabPabrikBtn.TextSize = 11; Instance.new("UICorner", TabPabrikBtn).CornerRadius = UDim.new(0, 6)
local TabAdvBtn = Instance.new("TextButton", TabNav); TabAdvBtn.Size = UDim2.new(0.49, 0, 1, 0); TabAdvBtn.Position = UDim2.new(0.51, 0, 0, 0); TabAdvBtn.BackgroundColor3 = Theme.Item; TabAdvBtn.Text = "Advanced & Delay"; TabAdvBtn.TextColor3 = Color3.new(1,1,1); TabAdvBtn.Font = Enum.Font.GothamBold; TabAdvBtn.TextSize = 11; Instance.new("UICorner", TabAdvBtn).CornerRadius = UDim.new(0, 6)

local PageContainer = Instance.new("Frame", TargetPage); PageContainer.Size = UDim2.new(1, 0, 1, -45); PageContainer.Position = UDim2.new(0, 0, 0, 45); PageContainer.BackgroundTransparency = 1
local PagePabrik = Instance.new("Frame", PageContainer); PagePabrik.Size = UDim2.new(1, 0, 0, 0); PagePabrik.BackgroundTransparency = 1; PagePabrik.AutomaticSize = Enum.AutomaticSize.Y; local UIListPabrik = Instance.new("UIListLayout", PagePabrik); UIListPabrik.SortOrder = Enum.SortOrder.LayoutOrder; UIListPabrik.Padding = UDim.new(0, 5)
local PageAdv = Instance.new("Frame", PageContainer); PageAdv.Size = UDim2.new(1, 0, 0, 0); PageAdv.BackgroundTransparency = 1; PageAdv.Visible = false; PageAdv.AutomaticSize = Enum.AutomaticSize.Y; local UIListAdv = Instance.new("UIListLayout", PageAdv); UIListAdv.SortOrder = Enum.SortOrder.LayoutOrder; UIListAdv.Padding = UDim.new(0, 5)

TabPabrikBtn.MouseButton1Click:Connect(function() PagePabrik.Visible = true; PageAdv.Visible = false; TabPabrikBtn.BackgroundColor3 = Theme.Purple; TabAdvBtn.BackgroundColor3 = Theme.Item end)
TabAdvBtn.MouseButton1Click:Connect(function() PagePabrik.Visible = false; PageAdv.Visible = true; TabPabrikBtn.BackgroundColor3 = Theme.Item; TabAdvBtn.BackgroundColor3 = Theme.Purple end)

local function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); Instance.new("UICorner", IndBg).CornerRadius = UDim.new(1,0)
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
    IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30)
    Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) 
end

local function CreateTextBox(Parent, Text, Default, Var) 
    local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame); Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left
    local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox 
end

local function CreateButton(Parent, Text, Callback) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) 
end

local function CreateDropdown(Parent, Text, DefaultOptions, Var) 
    local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""
    local Label = Instance.new("TextLabel", TopBtn); Label.Text = Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left
    local Icon = Instance.new("TextLabel", TopBtn); Icon.Text = "v"; Icon.TextColor3 = Theme.Purple; Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 12; Icon.Size = UDim2.new(0, 20, 1, 0); Icon.Position = UDim2.new(1, -25, 0, 0); Icon.BackgroundTransparency = 1
    local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Theme.Purple; Instance.new("UIListLayout", Scroll)
    
    local isOpen = false
    TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true); Icon.Text = "^" else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end end)
    local function RefreshOptions(Options) 
        for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, opt in ipairs(Options) do 
            local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11
            OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end) 
        end
        Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) 
    end
    RefreshOptions(DefaultOptions); return RefreshOptions 
end

CreateToggle(PagePabrik, "🚀 START SMART PABRIK", "EnablePabrik")
CreateToggle(PagePabrik, "Auto Collect Sapling (Pas Break)", "OnlyCollectSapling")
local RefreshSeedDropdown = CreateDropdown(PagePabrik, "Pilih Seed", ScanAvailableItems(), "SelectedSeed")
local RefreshBlockDropdown = CreateDropdown(PagePabrik, "Pilih Block", ScanAvailableItems(), "SelectedBlock")
CreateButton(PagePabrik, "🔄 Refresh Tas Item", function() local newItems = ScanAvailableItems(); RefreshSeedDropdown(newItems); RefreshBlockDropdown(newItems) end)

local d1 = Instance.new("Frame", PagePabrik); d1.Size=UDim2.new(1,0,0,2); d1.BackgroundColor3=Theme.Purple; d1.BorderSizePixel=0
CreateTextBox(PagePabrik, "Area Start X", getgenv().PabrikStartX, "PabrikStartX")
CreateTextBox(PagePabrik, "Area End X", getgenv().PabrikEndX, "PabrikEndX")
CreateTextBox(PagePabrik, "Area Start Y", getgenv().PabrikStartY, "PabrikStartY")
CreateTextBox(PagePabrik, "Area End Y", getgenv().PabrikEndY, "PabrikEndY")

local d2 = Instance.new("Frame", PagePabrik); d2.Size=UDim2.new(1,0,0,2); d2.BackgroundColor3=Theme.Purple; d2.BorderSizePixel=0
CreateTextBox(PagePabrik, "Block Threshold (Sisa)", getgenv().BlockThreshold, "BlockThreshold")
CreateTextBox(PagePabrik, "Keep Seed Amt (Sisa)", getgenv().KeepSeedAmt, "KeepSeedAmt")

CreateTextBox(PageAdv, "⚡ Walk Speed", getgenv().WalkSpeed, "WalkSpeed")
CreateTextBox(PageAdv, "Place Delay (ms)", getgenv().PlaceDelay, "PlaceDelay")
CreateTextBox(PageAdv, "Break Delay (ms)", getgenv().BreakDelay, "BreakDelay") 
CreateTextBox(PageAdv, "Hit Count (Pukulan)", getgenv().HitCount, "HitCount")

local d3 = Instance.new("Frame", PageAdv); d3.Size=UDim2.new(1,0,0,2); d3.BackgroundColor3=Theme.Purple; d3.BorderSizePixel=0
local BreakXBox = CreateTextBox(PageAdv, "Break Pos X", getgenv().BreakPosX, "BreakPosX")
local BreakYBox = CreateTextBox(PageAdv, "Break Pos Y", getgenv().BreakPosY, "BreakPosY")
CreateButton(PageAdv, "📍 Set Break Pos (Kamu)", function() 
    local H = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) 
    if H then 
        local bx = math.floor(H.Position.X/4.5+0.5); local by = math.floor(H.Position.Y/4.5+0.5)
        getgenv().BreakPosX = bx; getgenv().BreakPosY = by; BreakXBox.Text = tostring(bx); BreakYBox.Text = tostring(by) 
    end 
end)

local d4 = Instance.new("Frame", PageAdv); d4.Size=UDim2.new(1,0,0,2); d4.BackgroundColor3=Theme.Purple; d4.BorderSizePixel=0
local DropXBox = CreateTextBox(PageAdv, "Drop Pos X", getgenv().DropPosX, "DropPosX")
local DropYBox = CreateTextBox(PageAdv, "Drop Pos Y", getgenv().DropPosY, "DropPosY")
CreateButton(PageAdv, "📍 Set Drop Pos (Kamu)", function() 
    local H = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) 
    if H then 
        local dx = math.floor(H.Position.X/4.5+0.5); local dy = math.floor(H.Position.Y/4.5+0.5)
        getgenv().DropPosX = dx; getgenv().DropPosY = dy; DropXBox.Text = tostring(dx); DropYBox.Text = tostring(dy) 
    end 
end)

-- ========================================== --
-- [[ LOGIKA UTAMA: SMART PABRIK ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnablePabrik then
            if getgenv().SelectedSeed == "Kosong" or getgenv().SelectedBlock == "Kosong" then 
                task.wait(2)
            else
                local targetPanen = {}
                local targetTanam = {}

                -- 1. SCAN WORLD 
                local sX, eX = math.min(getgenv().PabrikStartX, getgenv().PabrikEndX), math.max(getgenv().PabrikStartX, getgenv().PabrikEndX)
                local sY, eY = math.min(getgenv().PabrikStartY, getgenv().PabrikEndY), math.max(getgenv().PabrikStartY, getgenv().PabrikEndY)

                for y = sY, eY do
                    if not getgenv().EnablePabrik then break end
                    local isEven = (y % 2 == 0)
                    local loopStartX = isEven and sX or eX
                    local loopEndX = isEven and eX or sX
                    local step = isEven and 1 or -1
                    
                    for x = loopStartX, loopEndX, step do
                        local yCol = RawWorldTiles[x]
                        if type(yCol) == "table" then
                            if IsTileSolid(x, y - 1) and IsTileEmptyForPlant(x, y) then
                                table.insert(targetTanam, {x = x, y = y})
                            end
                            if type(yCol[y]) == "table" then
                                for layer, data in pairs(yCol[y]) do
                                    local rawId = type(data) == "table" and data[1] or data
                                    local tileInfo = type(data) == "table" and data[2] or nil
                                    local tileStr = rawId
                                    if type(rawId) == "number" and WorldManager.NumberToStringMap then tileStr = WorldManager.NumberToStringMap[rawId] or rawId end
                                    
                                    if type(tileStr) == "string" and (string.find(string.lower(tileStr), "sapling") or string.find(string.lower(tileStr), "seed")) and tileInfo and tileInfo.at then
                                        local sapling = {x = x, y = y, name = tileStr, at = tileInfo.at, stage = tileInfo.stage}
                                        local isReady = false
                                        if sapling.stage and sapling.stage >= 3 then
                                            isReady = true
                                        else
                                            local targetMatang = GetExactGrowTime(sapling.name)
                                            if not targetMatang then
                                                BackupAIBelajarWaktu(sapling)
                                                targetMatang = getgenv().AIDictionary[sapling.name]
                                            end
                                            if targetMatang then
                                                local umurServer1 = os.time() - sapling.at
                                                local umurServer2 = workspace:GetServerTimeNow() - sapling.at
                                                if math.max(umurServer1, umurServer2) >= targetMatang then isReady = true end
                                            end
                                        end
                                        if isReady then table.insert(targetPanen, sapling) end
                                    end
                                end
                            end
                        end
                    end
                end

                local seedSlot = GetSlotByItemName(getgenv().SelectedSeed)
                local canPlant = (#targetTanam > 0)
                
                -- FLAG PRIORITAS:
                local didHarvest = (#targetPanen > 0)
                local didPlant = (canPlant and seedSlot ~= nil)
                
                -- KONDISI ANTI BENGONG: Kalo lahan kosong tapi gaada bibit, lewatin tanam dan langsung block farm
                local needToFarmBlock = false
                if not didHarvest and not didPlant then
                    needToFarmBlock = true
                end

                -- =============================================== --
                -- EKSEKUSI PANEN + SWEEP PER-BARIS (PER Y)
                -- =============================================== --
                if didHarvest then
                    for i, panen in ipairs(targetPanen) do
                        if not getgenv().EnablePabrik then break end
                        
                        if MoveSmartlyTo(panen.x, panen.y) then
                            task.wait(0.1)
                            pcall(function() 
                                local targetVec = Vector2.new(panen.x, panen.y)
                                if RemoteBreak:IsA("RemoteEvent") then RemoteBreak:FireServer(targetVec) else RemoteBreak:InvokeServer(targetVec) end
                            end)
                            task.wait(getgenv().BreakDelay)
                        end
                        
                        -- Cek apakah ini panenan terakhir di BARIS Y INI?
                        local nextPanen = targetPanen[i + 1]
                        if not nextPanen or nextPanen.y ~= panen.y then
                            -- Sweep 1 kotak kedepan
                            local stepDir = (panen.y % 2 == 0) and 1 or -1
                            MoveSmartlyTo(panen.x + stepDir, panen.y)
                            task.wait(0.3) 
                        end
                    end
                end

                -- =============================================== --
                -- EKSEKUSI TANAM
                -- =============================================== --
                if didPlant then
                    for _, spot in ipairs(targetTanam) do
                        if not getgenv().EnablePabrik then break end
                        seedSlot = GetSlotByItemName(getgenv().SelectedSeed)
                        if not seedSlot then break end -- Kalo di tengah jalan abis, setop
                        
                        if MoveSmartlyTo(spot.x, spot.y) then
                            task.wait(0.1)
                            pcall(function() 
                                local targetVec = Vector2.new(spot.x, spot.y); local targetStr = spot.x .. ", " .. spot.y
                                if RemotePlace:IsA("RemoteEvent") then 
                                    RemotePlace:FireServer(targetVec, seedSlot); RemotePlace:FireServer(targetStr, seedSlot) 
                                else RemotePlace:InvokeServer(targetVec, seedSlot) end
                            end)
                            task.wait(getgenv().PlaceDelay)
                        end
                    end
                end

                -- =============================================== --
                -- PABRIK BLOCK & DROP SEED (STRICT THRESHOLD)
                -- =============================================== --
                if needToFarmBlock and getgenv().EnablePabrik then
                    local blockSlot = GetSlotByItemName(getgenv().SelectedBlock)
                    
                    if blockSlot then
                        if MoveSmartlyTo(getgenv().BreakPosX, getgenv().BreakPosY) then
                            local BreakTarget = Vector2.new(getgenv().BreakPosX - 1, getgenv().BreakPosY)
                            
                            -- KUNCI TERBESAR: Bot cuma keluar dari loop ini KALAU blok beneran udah di bawah/sama dengan threshold.
                            while getgenv().EnablePabrik do
                                local currentBlockAmt = GetItemAmountByItemName(getgenv().SelectedBlock)
                                blockSlot = GetSlotByItemName(getgenv().SelectedBlock)
                                
                                -- JIKA BLOK DI TAS UDAH SEDIKIT (SENTUH THRESHOLD)
                                if currentBlockAmt <= getgenv().BlockThreshold or not blockSlot then
                                    local hasAny, _ = CheckDropsType(BreakTarget.X, BreakTarget.Y)
                                    if hasAny then
                                        TrueGhostCollect(BreakTarget.X, BreakTarget.Y, false) -- PUNGUT SEMUANYA
                                    end
                                    break -- Keluar dari loop pabrik, bot bakal jalan nge-drop seed terus scan ladang
                                end
                                
                                -- KALAU BLOK MASIH BANYAK, HAJAR TERUS!
                                RemotePlace:FireServer(BreakTarget, blockSlot)
                                task.wait(getgenv().PlaceDelay) 
                                
                                for hit = 1, getgenv().HitCount do
                                    if not getgenv().EnablePabrik then break end
                                    RemoteBreak:FireServer(BreakTarget)
                                    task.wait(getgenv().BreakDelay)
                                end
                                
                                -- Cek Sapling Drop
                                if getgenv().OnlyCollectSapling then
                                    local _, hasSapling = CheckDropsType(BreakTarget.X, BreakTarget.Y)
                                    if hasSapling then
                                        TrueGhostCollect(BreakTarget.X, BreakTarget.Y, true) -- PUNGUT SAPLINGNYA DOANG
                                    end
                                end
                            end
                        end
                    end

                    -- AUTO DROP SEED KELAR BATCH
                    if getgenv().EnablePabrik then
                        local currentSeedAmt = GetItemAmountByItemName(getgenv().SelectedSeed)
                        if currentSeedAmt > getgenv().KeepSeedAmt then
                            if MoveSmartlyTo(getgenv().DropPosX, getgenv().DropPosY) then
                                task.wait(1.5)
                                while getgenv().EnablePabrik do
                                    local current = GetItemAmountByItemName(getgenv().SelectedSeed)
                                    local toDrop = current - getgenv().KeepSeedAmt 
                                    if toDrop <= 0 then break end
                                    local dropNow = math.min(toDrop, 200)
                                    if DropItemLogic(getgenv().SelectedSeed, dropNow) then task.wait(getgenv().DropDelay + 0.3) else break end
                                end
                                
                                pcall(function() 
                                    if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
                                    for _, gui in pairs(LP.PlayerGui:GetDescendants()) do 
                                        if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end 
                                    end 
                                end)
                                task.wait(0.1)
                                pcall(function() if UIManager and type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
