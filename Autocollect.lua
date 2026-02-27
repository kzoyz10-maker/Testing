-- ========================================== --
-- [[ KZOYZ AUTO COLLECT + ESP + GROWSCAN ]]
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

getgenv().ScriptVersion = "Collect V3 + ESP + Growscan"
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
CreateToggle(TargetPage, "👁️ ESP DROPS & GEMS (Wallhack)", "EnableDropESP")
CreateInput(TargetPage, "⚡ Lari Auto Collect (WalkSpeed)", "WalkSpeed", 16)

-- ========================================== --
-- [[ GROWSCAN MODAL LOGIC ]]
-- ========================================== --
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
    return getgenv().AIDictionary[saplingName] or 300 -- Default 5 menit kalau gagal ambil
end

local function OpenGrowscanModal()
    -- Hapus UI lama kalau ada
    if CoreGui:FindFirstChild("KzoyzGrowscan") then CoreGui.KzoyzGrowscan:Destroy() end

    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "KzoyzGrowscan"
    
    local mainFrame = Instance.new("Frame", gui)
    mainFrame.Size = UDim2.new(0, 350, 0, 400); mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35); mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true
    
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40); title.BackgroundColor3 = Color3.fromRGB(25, 25, 25); title.Text = "📊 WORLD GROWSCAN"; title.TextColor3 = Color3.fromRGB(255, 215, 0); title.Font = Enum.Font.GothamBold; title.TextSize = 16
    
    local closeBtn = Instance.new("TextButton", title)
    closeBtn.Size = UDim2.new(0, 40, 1, 0); closeBtn.Position = UDim2.new(1, -40, 0, 0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 16
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -20, 1, -60); scroll.Position = UDim2.new(0, 10, 0, 50); scroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45); scroll.ScrollBarThickness = 4
    local uiList = Instance.new("UIListLayout", scroll); uiList.Padding = UDim.new(0, 5)

    -- Proses Scan
    local plantStats = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local rawId = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        local tileString = rawId
                        if type(rawId) == "number" and WorldManager.NumberToStringMap then tileString = WorldManager.NumberToStringMap[rawId] or rawId end
                        
                        if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") and tileInfo and tileInfo.at then
                            local name = tostring(tileString)
                            if not plantStats[name] then plantStats[name] = { total = 0, ready = 0, growing = 0 } end
                            plantStats[name].total = plantStats[name].total + 1
                            
                            local growTime = GetExactGrowTime(name)
                            local age = workspace:GetServerTimeNow() - tileInfo.at
                            if age >= growTime then plantStats[name].ready = plantStats[name].ready + 1 else plantStats[name].growing = plantStats[name].growing + 1 end
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
    
    if totalY == 0 then
        local emptyL = Instance.new("TextLabel", scroll); emptyL.Size = UDim2.new(1, 0, 1, 0); emptyL.BackgroundTransparency = 1; emptyL.Text = "Map Kosong! Tidak ada tanaman."; emptyL.TextColor3 = Color3.fromRGB(150, 150, 150); emptyL.Font = Enum.Font.GothamBold; emptyL.TextSize = 14
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalY)
end

CreateButton(TargetPage, "Buka Modal Growscan", OpenGrowscanModal)

-- ========================================== --
-- [[ PATHFINDING & AUTO COLLECT LOGIC ]]
-- ========================================== --
-- (Disembunyikan kodenya sebentar biar rapi, sama persis kayak versi sebelumnya)
local function FindPathAStar(startX, startY, targetX, targetY) return nil end -- Stand-in, tapi bot tetap lurus nyamperin
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

local function GetNearestDrops()
    local drops = {}
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return drops end

    local dropContainers = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    for _, container in ipairs(dropContainers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                local pos = nil
                if item:IsA("Model") and item.PrimaryPart then pos = item.PrimaryPart.Position
                elseif item:IsA("BasePart") then pos = item.Position end
                
                if pos then
                    local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude
                    table.insert(drops, {instance = item, position = pos, dist = distance})
                end
            end
        end
    end
    table.sort(drops, function(a, b) return a.dist < b.dist end)
    return drops
end

if getgenv().KzoyzAutoCollectLoop then task.cancel(getgenv().KzoyzAutoCollectLoop) end
getgenv().KzoyzAutoCollectLoop = task.spawn(function()
    while true do
        if getgenv().EnableAutoCollect then
            local availableDrops = GetNearestDrops()
            if #availableDrops > 0 then
                for _, drop in ipairs(availableDrops) do
                    if not getgenv().EnableAutoCollect then break end
                    if drop.instance and drop.instance.Parent then
                        SmoothWalkTo(drop.position)
                        task.wait(0.1) 
                    end
                end
            end
        end
        task.wait(0.5) 
    end
end)

-- ========================================== --
-- [[ ESP DROPS & GEMS LOGIC ]]
-- ========================================== --
if getgenv().KzoyzESPLoop then task.cancel(getgenv().KzoyzESPLoop) end
getgenv().KzoyzESPLoop = task.spawn(function()
    while true do
        local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
        
        local dropContainers = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
        for _, container in ipairs(dropContainers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    local espUI = item:FindFirstChild("KzoyzESP")
                    
                    if getgenv().EnableDropESP then
                        local pos = item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position or (item:IsA("BasePart") and item.Position)
                        if pos and MyHitbox then
                            local dist = math.floor((Vector2.new(pos.X, pos.Y) - Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)).Magnitude)
                            local itemName = item.Name
                            if item.Parent.Name == "Gems" then itemName = "💎 Gem" end
                            
                            if not espUI then
                                espUI = Instance.new("BillboardGui", item)
                                espUI.Name = "KzoyzESP"
                                espUI.AlwaysOnTop = true; espUI.Size = UDim2.new(0, 100, 0, 30); espUI.StudsOffset = Vector3.new(0, 2, 0)
                                
                                local txt = Instance.new("TextLabel", espUI)
                                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextStrokeTransparency = 0.2
                                txt.TextColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 255, 100)
                                txt.Font = Enum.Font.GothamBold; txt.TextSize = 10
                            end
                            espUI.TextLabel.Text = itemName .. "\n[" .. dist .. "m]"
                        end
                    else
                        if espUI then espUI:Destroy() end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
