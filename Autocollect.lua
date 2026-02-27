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

getgenv().ScriptVersion = "Collect V12 + Tab UI + Stack Counter"
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

CreateToggle(TargetPage, "START AUTO COLLECT", "EnableAutoCollect")
CreateToggle(TargetPage, "ESP ITEMS", "EnableDropESP")
CreateInput(TargetPage, "WALK SPEED", "WalkSpeed", 16)

-- ========================================== --
-- [[ HELPER: NAMA & STACK SIZE (JUMLAH ISI) ]]
-- ========================================== --
local function GetItemDetails(item)
    local realName = nil
    local stackAmount = 1 -- Default isi 1
    
    -- 1. Cari jumlah tumpukan (Stack Size)
    for attrName, attrValue in pairs(item:GetAttributes()) do
        local lowerKey = string.lower(attrName)
        if lowerKey == "amount" or lowerKey == "count" or lowerKey == "quantity" then stackAmount = tonumber(attrValue) or 1 end
    end
    for _, child in ipairs(item:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("NumberValue") then
            local lowerKey = string.lower(child.Name)
            if lowerKey == "amount" or lowerKey == "count" or lowerKey == "quantity" then stackAmount = tonumber(child.Value) or 1 end
        end
    end

    -- 2. Cari Nama Item Asli
    for attrName, attrValue in pairs(item:GetAttributes()) do
        local lowerKey = string.lower(attrName)
        if lowerKey ~= "amount" and lowerKey ~= "count" and lowerKey ~= "quantity" then
            if type(attrValue) == "number" and WorldManager.NumberToStringMap[attrValue] then realName = WorldManager.NumberToStringMap[attrValue]; break end
            if type(attrValue) == "string" and string.len(attrValue) > 2 then realName = attrValue; break end
        end
    end

    if not realName then
        for _, child in ipairs(item:GetChildren()) do
            if child:IsA("StringValue") and child.Value ~= "" then realName = child.Value; break end
            if (child:IsA("IntValue") or child:IsA("NumberValue")) and string.lower(child.Name) ~= "amount" and string.lower(child.Name) ~= "count" then
                if WorldManager.NumberToStringMap[child.Value] then realName = WorldManager.NumberToStringMap[child.Value]; break end
            end
        end
    end

    if not realName then realName = item.Name end
    return realName, stackAmount
end

-- ========================================== --
-- [[ GROWSCAN MODAL (TAB SYSTEM) ]]
-- ========================================== --
local function FormatCoords(coordsTable)
    if #coordsTable == 0 then return "-" end
    if #coordsTable > 8 then
        local shortList = {}
        for i=1, 8 do table.insert(shortList, coordsTable[i]) end
        return table.concat(shortList, ", ") .. " (+" .. (#coordsTable - 8) .. " lg)"
    end
    return table.concat(coordsTable, ", ")
end

local function RenderGrowscanContent(scrollTanaman, scrollDrops)
    -- Bersihkan isi sebelumnya
    for _, child in ipairs(scrollTanaman:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
    for _, child in ipairs(scrollDrops:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end

    -- =================== BAGIAN TANAMAN ===================
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
                            if not plantStats[name] then plantStats[name] = { total = 0, ready = 0, growing = 0, readyCoords = {}, growCoords = {} } end
                            plantStats[name].total = plantStats[name].total + 1
                            
                            local baseId = string.gsub(name, "_sapling", "")
                            local growTime = 300
                            pcall(function()
                                local itemData = ItemsManager.ItemsData[baseId] or ItemsManager.ItemsData[name]
                                for k, v in pairs(itemData) do if type(v) == "number" and (k:lower():find("grow") or k:lower():find("time")) then growTime = v; break end end
                            end)

                            local age = workspace:GetServerTimeNow() - tileInfo.at
                            if age >= growTime then 
                                plantStats[name].ready = plantStats[name].ready + 1
                                table.insert(plantStats[name].readyCoords, "("..x..","..y..")")
                            else 
                                plantStats[name].growing = plantStats[name].growing + 1 
                                table.insert(plantStats[name].growCoords, "("..x..","..y..")")
                            end
                        end
                    end
                end
            end
        end
    end

    local totalY_Tanaman = 0
    for plantName, stat in pairs(plantStats) do
        local frame = Instance.new("Frame", scrollTanaman); frame.Size = UDim2.new(1, 0, 0, 85); frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        local lblName = Instance.new("TextLabel", frame); lblName.Size = UDim2.new(1, -10, 0, 20); lblName.Position = UDim2.new(0, 10, 0, 5); lblName.BackgroundTransparency = 1; lblName.Text = "🌱 " .. string.upper(string.gsub(plantName, "_sapling", "")); lblName.TextColor3 = Color3.fromRGB(150, 255, 150); lblName.Font = Enum.Font.GothamBold; lblName.TextXAlignment = Enum.TextXAlignment.Left; lblName.TextSize = 14
        local lblStat = Instance.new("TextLabel", frame); lblStat.Size = UDim2.new(1, -10, 0, 20); lblStat.Position = UDim2.new(0, 10, 0, 25); lblStat.BackgroundTransparency = 1; lblStat.Text = "Pohon: " .. stat.total .. " | ✅ Ready: " .. stat.ready .. " | ⏳ Grow: " .. stat.growing; lblStat.TextColor3 = Color3.fromRGB(200, 200, 200); lblStat.Font = Enum.Font.Gotham; lblStat.TextXAlignment = Enum.TextXAlignment.Left; lblStat.TextSize = 12
        local lblCoords = Instance.new("TextLabel", frame); lblCoords.Size = UDim2.new(1, -20, 0, 35); lblCoords.Position = UDim2.new(0, 10, 0, 45); lblCoords.BackgroundTransparency = 1; lblCoords.Text = "📍 XY Ready: " .. FormatCoords(stat.readyCoords); lblCoords.TextColor3 = Color3.fromRGB(180, 220, 255); lblCoords.Font = Enum.Font.Gotham; lblCoords.TextXAlignment = Enum.TextXAlignment.Left; lblCoords.TextYAlignment = Enum.TextYAlignment.Top; lblCoords.TextSize = 11; lblCoords.TextWrapped = true
        totalY_Tanaman = totalY_Tanaman + 90
    end
    scrollTanaman.CanvasSize = UDim2.new(0, 0, 0, totalY_Tanaman)

    -- =================== BAGIAN DROPS & GEMS ===================
    local dropStats = {}
    local dropsFolder = workspace:FindFirstChild("Drops")
    local gemsFolder = workspace:FindFirstChild("Gems")
    
    if dropsFolder then
        for _, item in ipairs(dropsFolder:GetChildren()) do
            local name, amount = GetItemDetails(item)
            if not dropStats[name] then dropStats[name] = { stacks = 0, totalItems = 0, coords = {} } end
            dropStats[name].stacks = dropStats[name].stacks + 1
            dropStats[name].totalItems = dropStats[name].totalItems + amount
            local pos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
            if pos then table.insert(dropStats[name].coords, "("..math.floor(pos.X / getgenv().GridSize)..","..math.floor(pos.Y / getgenv().GridSize)..")") end
        end
    end

    local totalGems = 0
    if gemsFolder then
        for _, item in ipairs(gemsFolder:GetChildren()) do
            local _, amount = GetItemDetails(item) 
            totalGems = totalGems + amount
        end
    end

    local totalY_Drops = 0

    -- Banner Gems
    local gemFrame = Instance.new("Frame", scrollDrops); gemFrame.Size = UDim2.new(1, 0, 0, 40); gemFrame.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
    local gemLbl = Instance.new("TextLabel", gemFrame); gemLbl.Size = UDim2.new(1, -10, 1, 0); gemLbl.Position = UDim2.new(0, 10, 0, 0); gemLbl.BackgroundTransparency = 1; gemLbl.Text = "💎 TOTAL GEMS IN WORLD: " .. totalGems; gemLbl.TextColor3 = Color3.fromRGB(100, 200, 255); gemLbl.Font = Enum.Font.GothamBold; gemLbl.TextXAlignment = Enum.TextXAlignment.Left; gemLbl.TextSize = 14
    totalY_Drops = totalY_Drops + 45

    for dName, dData in pairs(dropStats) do
        local dFrame = Instance.new("Frame", scrollDrops); dFrame.Size = UDim2.new(1, 0, 0, 55); dFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        local dLbl = Instance.new("TextLabel", dFrame); dLbl.Size = UDim2.new(1, -10, 0, 20); dLbl.Position = UDim2.new(0, 10, 0, 5); dLbl.BackgroundTransparency = 1; dLbl.Text = "📦 " .. string.upper(tostring(dName)) .. " | Amount: " .. dData.totalItems .. " (" .. dData.stacks .. " Stack)"; dLbl.TextColor3 = Color3.fromRGB(255, 215, 0); dLbl.Font = Enum.Font.GothamBold; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextSize = 12
        local dCoords = Instance.new("TextLabel", dFrame); dCoords.Size = UDim2.new(1, -10, 0, 20); dCoords.Position = UDim2.new(0, 10, 0, 25); dCoords.BackgroundTransparency = 1; dCoords.Text = "📍 XY: " .. FormatCoords(dData.coords); dCoords.TextColor3 = Color3.fromRGB(180, 220, 255); dCoords.Font = Enum.Font.Gotham; dCoords.TextXAlignment = Enum.TextXAlignment.Left; dCoords.TextSize = 11; dCoords.TextWrapped = true
        totalY_Drops = totalY_Drops + 60
    end
    scrollDrops.CanvasSize = UDim2.new(0, 0, 0, totalY_Drops)
end

local function OpenGrowscanModal()
    if CoreGui:FindFirstChild("KzoyzGrowscan") then CoreGui.KzoyzGrowscan:Destroy() end

    local gui = Instance.new("ScreenGui", CoreGui); gui.Name = "KzoyzGrowscan"
    local mainFrame = Instance.new("Frame", gui); mainFrame.Size = UDim2.new(0, 420, 0, 500); mainFrame.Position = UDim2.new(0.5, -210, 0.5, -250); mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35); mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
    
    local title = Instance.new("TextLabel", mainFrame); title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundColor3 = Color3.fromRGB(20, 20, 20); title.Text = "📊 GROWSCAN"; title.TextColor3 = Color3.fromRGB(255, 215, 0); title.Font = Enum.Font.GothamBold; title.TextSize = 15

    local closeBtn = Instance.new("TextButton", title); closeBtn.Size = UDim2.new(0, 40, 1, 0); closeBtn.Position = UDim2.new(1, -40, 0, 0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 16
    
    -- TAB BUTTONS
    local tabFrame = Instance.new("Frame", mainFrame); tabFrame.Size = UDim2.new(1, 0, 0, 35); tabFrame.Position = UDim2.new(0, 0, 0, 40); tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    local btnTanaman = Instance.new("TextButton", tabFrame); btnTanaman.Size = UDim2.new(0.5, 0, 1, 0); btnTanaman.Position = UDim2.new(0, 0, 0, 0); btnTanaman.BackgroundColor3 = Color3.fromRGB(45, 45, 45); btnTanaman.Text = "🌱 TREE"; btnTanaman.TextColor3 = Color3.fromRGB(255, 255, 255); btnTanaman.Font = Enum.Font.GothamBold; btnTanaman.TextSize = 13
    local btnDrops = Instance.new("TextButton", tabFrame); btnDrops.Size = UDim2.new(0.5, 0, 1, 0); btnDrops.Position = UDim2.new(0.5, 0, 0, 0); btnDrops.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btnDrops.Text = "📦 ITEMS & GEMS"; btnDrops.TextColor3 = Color3.fromRGB(150, 150, 150); btnDrops.Font = Enum.Font.GothamBold; btnDrops.TextSize = 13

    -- SCROLL FRAMES
    local scrollTanaman = Instance.new("ScrollingFrame", mainFrame); scrollTanaman.Size = UDim2.new(1, -20, 1, -85); scrollTanaman.Position = UDim2.new(0, 10, 0, 80); scrollTanaman.BackgroundColor3 = Color3.fromRGB(40, 40, 40); scrollTanaman.ScrollBarThickness = 4
    local uiList1 = Instance.new("UIListLayout", scrollTanaman); uiList1.Padding = UDim.new(0, 5)
    
    local scrollDrops = Instance.new("ScrollingFrame", mainFrame); scrollDrops.Size = UDim2.new(1, -20, 1, -85); scrollDrops.Position = UDim2.new(0, 10, 0, 80); scrollDrops.BackgroundColor3 = Color3.fromRGB(40, 40, 40); scrollDrops.ScrollBarThickness = 4; scrollDrops.Visible = false
    local uiList2 = Instance.new("UIListLayout", scrollDrops); uiList2.Padding = UDim.new(0, 5)

    -- TAB LOGIC
    btnTanaman.MouseButton1Click:Connect(function()
        scrollTanaman.Visible = true; scrollDrops.Visible = false
        btnTanaman.BackgroundColor3 = Color3.fromRGB(45, 45, 45); btnTanaman.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnDrops.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btnDrops.TextColor3 = Color3.fromRGB(150, 150, 150)
    end)
    btnDrops.MouseButton1Click:Connect(function()
        scrollTanaman.Visible = false; scrollDrops.Visible = true
        btnDrops.BackgroundColor3 = Color3.fromRGB(45, 45, 45); btnDrops.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnTanaman.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btnTanaman.TextColor3 = Color3.fromRGB(150, 150, 150)
    end)

    local isModalOpen = true
    closeBtn.MouseButton1Click:Connect(function() isModalOpen = false; gui:Destroy() end)
    
    task.spawn(function()
        while isModalOpen and gui.Parent do
            pcall(function() RenderGrowscanContent(scrollTanaman, scrollDrops) end)
            task.wait(1.5)
        end
    end)
end

CreateButton(TargetPage, "Growscan", OpenGrowscanModal)

-- ========================================== --
-- [[ PATHFINDING (A-STAR) SMART COLLECT ]]
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
        BlockSolidityCache[nameStr] = true; return true
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
        for i = 2, #openSet do if fScore[openSet[i].key] < fScore[current.key] then current = openSet[i]; currentIndex = i end end
        if current.x == targetX and current.y == targetY then
            local path, currKey = {}, current.key
            while cameFrom[currKey] do local node = cameFrom[currKey]; table.insert(path, 1, {x = current.x, y = current.y}); current = node; currKey = node.x .. "," .. node.y end
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
            MyHitbox.CFrame = CFrame.new(startPos:Lerp(targetPos, math.clamp(t / duration, 0, 1)))
            if PlayerMovement then pcall(function() PlayerMovement.Position = startPos:Lerp(targetPos, math.clamp(t / duration, 0, 1)) end) end
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
    local route = FindPathAStar(math.round(MyHitbox.Position.X / getgenv().GridSize), math.round(MyHitbox.Position.Y / getgenv().GridSize), math.round(targetPos.X / getgenv().GridSize), math.round(targetPos.Y / getgenv().GridSize))
    if route then
        for _, stepPos in ipairs(route) do
            if not getgenv().EnableAutoCollect then break end
            if not SmoothWalkTo(Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, MyHitbox.Position.Z)) then return false end
        end
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
                for _, container in ipairs({workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems")}) do
                    if container then
                        for _, item in ipairs(container:GetChildren()) do
                            local pos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
                            if pos then table.insert(drops, {instance = item, position = pos, dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude}) end
                        end
                    end
                end
                table.sort(drops, function(a, b) return a.dist < b.dist end)
                if #drops > 0 and drops[1].instance.Parent then MoveSmartlyToDrop(drops[1].position); task.wait(0.1) end
            end
        end
        task.wait(0.2) 
    end
end)

-- ========================================== --
-- [[ TRACER ESP LOGIC ]]
-- ========================================== --
local ESPGui = CoreGui:FindFirstChild("KzoyzESPGui")
if not ESPGui then ESPGui = Instance.new("ScreenGui", CoreGui); ESPGui.Name = "KzoyzESPGui"; ESPGui.IgnoreGuiInset = true end
local TracerLines = {}

local function GetLineFrame(item)
    if not TracerLines[item] then
        local line = Instance.new("Frame", ESPGui); line.AnchorPoint = Vector2.new(0.5, 0.5); line.BorderSizePixel = 0
        line.BackgroundColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 255, 0)
        TracerLines[item] = line
    end
    return TracerLines[item]
end

if getgenv().KzoyzESPLoop then getgenv().KzoyzESPLoop:Disconnect() end
getgenv().KzoyzESPLoop = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not getgenv().EnableDropESP then ESPGui:ClearAllChildren(); TracerLines = {}; return end
        local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
        if not MyHitbox then return end

        local activeItems = {}
        for _, container in ipairs({workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems")}) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    activeItems[item] = true
                    local targetPos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
                    if targetPos then
                        local espUI = item:FindFirstChild("KzoyzTextESP")
                        local dist = math.floor((Vector2.new(targetPos.X, targetPos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude)
                        if not espUI then
                            espUI = Instance.new("BillboardGui", item); espUI.Name = "KzoyzTextESP"; espUI.AlwaysOnTop = true; espUI.Size = UDim2.new(0, 150, 0, 30); espUI.StudsOffset = Vector3.new(0, 2, 0)
                            local txt = Instance.new("TextLabel", espUI); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextStrokeTransparency = 0.2
                            txt.TextColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 255, 100); txt.Font = Enum.Font.GothamBold; txt.TextSize = 10; txt.TextWrapped = true
                        end
                        
                        local realName, stackAmount = GetItemDetails(item)
                        local displayName = item.Parent.Name == "Gems" and "💎 Gem x" .. stackAmount or string.upper(tostring(realName)) .. " x" .. stackAmount
                        espUI.TextLabel.Text = displayName .. "\n[" .. dist .. "m]"

                        local line = GetLineFrame(item)
                        local startScreen = Camera:WorldToViewportPoint(MyHitbox.Position); local endScreen = Camera:WorldToViewportPoint(targetPos)
                        if endScreen.Z > 0 then
                            line.Visible = true; local p1 = Vector2.new(startScreen.X, startScreen.Y); local p2 = Vector2.new(endScreen.X, endScreen.Y)
                            line.Size = UDim2.new(0, (p1 - p2).Magnitude, 0, 1.5); line.Position = UDim2.new(0, (p1.X + p2.X) / 2, 0, (p1.Y + p2.Y) / 2)
                            line.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end

        for item, line in pairs(TracerLines) do
            if not activeItems[item] then line:Destroy(); TracerLines[item] = nil; if item and item:FindFirstChild("KzoyzTextESP") then item.KzoyzTextESP:Destroy() end end
        end
    end)
end)
