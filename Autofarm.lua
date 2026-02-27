-- [[ ========================================================= ]] --
-- [[ KZOYZ HUB - MASTER AUTO FARM & TRUE GHOST COLLECT (v8.96) ]] --
-- [[ ========================================================= ]] --

local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

getgenv().ScriptVersion = "Auto Farm v8.96 (Tab UI & Scroll Fix)" 

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser") 
local RunService = game:GetService("RunService")

-- [[ ========================================================= ]] --
-- [[ 🧹 CLEANUP SYSTEM (ANTI-STACKING / ANTI-NGEBUT)           ]] --
-- [[ ========================================================= ]] --
if getgenv().KzoyzFarmLoop then task.cancel(getgenv().KzoyzFarmLoop); getgenv().KzoyzFarmLoop = nil end
if getgenv().KzoyzHeartbeat then getgenv().KzoyzHeartbeat:Disconnect(); getgenv().KzoyzHeartbeat = nil end
if getgenv().KzoyzAntiAFK then getgenv().KzoyzAntiAFK:Disconnect(); getgenv().KzoyzAntiAFK = nil end

-- ========================================== --
getgenv().ActionDelay = 0.15 
getgenv().GridSize = 4.5 
-- ========================================== --

getgenv().MasterAutoFarm = false; 
getgenv().AutoCollect = false; 
getgenv().AutoSaplingMode = false; 
getgenv().AntiAFK = true; 
getgenv().HitCount = 3;
getgenv().BreakDelayMs = 150; 
getgenv().WaitDropMs = 250;  
getgenv().WalkSpeedMs = 100; 

-- Target Settings
getgenv().TargetFarmBlock = "Auto (Equipped)"
getgenv().AutoDropSapling = false
getgenv().SaplingThreshold = 50
getgenv().TargetSaplingName = "Dirt Sapling"

getgenv().SelectedTiles = {{x = 0, y = 1}}
getgenv().IsGhosting = false
getgenv().HoldCFrame = nil

local PlayerMovement
task.spawn(function() pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end) end)

-- MODULE INVENTORY ASLI
local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

local function GetSlotByItemID(targetID)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
end

local function GetItemAmountByID(targetID)
    local total = 0
    if not InventoryMod or not InventoryMod.Stacks then return total end
    for _, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            total = total + (data.Amount or 1)
        end
    end
    return total
end

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
    table.sort(items)
    return items
end

local function FindHotbarModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindHotbarModule()

-- UI Theme
local Theme = { 
    Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), 
    Purple = Color3.fromRGB(140, 80, 255), DarkBlue = Color3.fromRGB(25, 30, 45),    
    TileOff = Color3.fromRGB(45, 55, 80), TileOn = Color3.fromRGB(240, 160, 60), TileYou = Color3.fromRGB(100, 200, 100),  
}

-- [[ ========================================================= ]] --
-- [[ SISTEM TAB UI BARU ]]
-- [[ ========================================================= ]] --
-- Hapus isi lama dari TargetPage kalau ada
for _, v in pairs(TargetPage:GetChildren()) do if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then v:Destroy() end end

local TabNav = Instance.new("Frame", TargetPage)
TabNav.Size = UDim2.new(1, 0, 0, 35)
TabNav.BackgroundTransparency = 1
TabNav.ZIndex = 2

local TabFarmBtn = Instance.new("TextButton", TabNav)
TabFarmBtn.Size = UDim2.new(0.49, 0, 1, 0)
TabFarmBtn.BackgroundColor3 = Theme.Purple
TabFarmBtn.Text = "Farm Settings"
TabFarmBtn.TextColor3 = Color3.new(1,1,1)
TabFarmBtn.Font = Enum.Font.GothamBold
TabFarmBtn.TextSize = 12
Instance.new("UICorner", TabFarmBtn).CornerRadius = UDim.new(0, 6)

local TabSeedBtn = Instance.new("TextButton", TabNav)
TabSeedBtn.Size = UDim2.new(0.49, 0, 1, 0)
TabSeedBtn.Position = UDim2.new(0.51, 0, 0, 0)
TabSeedBtn.BackgroundColor3 = Theme.Item
TabSeedBtn.Text = "Seed Settings"
TabSeedBtn.TextColor3 = Color3.new(1,1,1)
TabSeedBtn.Font = Enum.Font.GothamBold
TabSeedBtn.TextSize = 12
Instance.new("UICorner", TabSeedBtn).CornerRadius = UDim.new(0, 6)

local PageContainer = Instance.new("Frame", TargetPage)
PageContainer.Size = UDim2.new(1, 0, 1, -45)
PageContainer.Position = UDim2.new(0, 0, 0, 45)
PageContainer.BackgroundTransparency = 1

local PageFarm = Instance.new("ScrollingFrame", PageContainer)
PageFarm.Size = UDim2.new(1, 0, 1, 0)
PageFarm.BackgroundTransparency = 1
PageFarm.ScrollBarThickness = 3
PageFarm.BorderSizePixel = 0
local UIListFarm = Instance.new("UIListLayout", PageFarm)
UIListFarm.SortOrder = Enum.SortOrder.LayoutOrder
UIListFarm.Padding = UDim.new(0, 5)
UIListFarm:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PageFarm.CanvasSize = UDim2.new(0, 0, 0, UIListFarm.AbsoluteContentSize.Y + 20) end)

local PageSeed = Instance.new("ScrollingFrame", PageContainer)
PageSeed.Size = UDim2.new(1, 0, 1, 0)
PageSeed.BackgroundTransparency = 1
PageSeed.ScrollBarThickness = 3
PageSeed.BorderSizePixel = 0
PageSeed.Visible = false
local UIListSeed = Instance.new("UIListLayout", PageSeed)
UIListSeed.SortOrder = Enum.SortOrder.LayoutOrder
UIListSeed.Padding = UDim.new(0, 5)
UIListSeed:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PageSeed.CanvasSize = UDim2.new(0, 0, 0, UIListSeed.AbsoluteContentSize.Y + 20) end)

TabFarmBtn.MouseButton1Click:Connect(function()
    PageFarm.Visible = true; PageSeed.Visible = false
    TabFarmBtn.BackgroundColor3 = Theme.Purple; TabSeedBtn.BackgroundColor3 = Theme.Item
end)

TabSeedBtn.MouseButton1Click:Connect(function()
    PageFarm.Visible = false; PageSeed.Visible = true
    TabFarmBtn.BackgroundColor3 = Theme.Item; TabSeedBtn.BackgroundColor3 = Theme.Purple
end)

-- [[ ========================================================= ]] --
-- [[ FUNGSI BUILDER UI ]]
-- [[ ========================================================= ]] --
function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local T = Instance.new("TextLabel"); T.Parent = Btn; T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame"); IndBg.Parent = Btn; IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30); Instance.new("UICorner", IndBg).CornerRadius = UDim.new(1,0)
    local Dot = Instance.new("Frame"); Dot.Parent = IndBg; Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

function CreateInput(Parent, Text, Default, Var)
    local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.6, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; 
    local InputBg = Instance.new("Frame"); InputBg.Parent = Frame; InputBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25); InputBg.Size = UDim2.new(0.3, 0, 0, 25); InputBg.Position = UDim2.new(1, -10, 0.5, 0); InputBg.AnchorPoint = Vector2.new(1, 0.5); Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0, 4)
    local TextBox = Instance.new("TextBox"); TextBox.Parent = InputBg; TextBox.BackgroundTransparency = 1; TextBox.Size = UDim2.new(1, 0, 1, 0); TextBox.Font = Enum.Font.GothamSemibold; TextBox.TextSize = 12; TextBox.TextColor3 = Color3.new(1,1,1); TextBox.Text = tostring(Default)
    TextBox.FocusLost:Connect(function() local num = tonumber(TextBox.Text); if num then getgenv()[Var] = math.floor(num) else TextBox.Text = tostring(getgenv()[Var]) end end)
end

function CreateDynamicDropdown(Parent, Text, DefaultText, GetOptionsFunc, Callback)
    local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ZIndex = 10; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.ZIndex = 11
    
    local Btn = Instance.new("TextButton"); Btn.Parent = Frame; Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Btn.Size = UDim2.new(0.4, 0, 0, 25); Btn.Position = UDim2.new(1, -10, 0.5, 0); Btn.AnchorPoint = Vector2.new(1, 0.5); Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 12; Btn.TextColor3 = Color3.new(1,1,1); Btn.Text = DefaultText; Btn.TextTruncate = Enum.TextTruncate.AtEnd; Btn.ZIndex = 12; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    local DropdownList = Instance.new("ScrollingFrame"); DropdownList.Parent = Frame; DropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 30); DropdownList.Size = UDim2.new(0.4, 0, 0, 120); DropdownList.Position = UDim2.new(1, -10, 1, 0); DropdownList.AnchorPoint = Vector2.new(1, 0); DropdownList.ScrollBarThickness = 2; DropdownList.Visible = false; DropdownList.ZIndex = 100; Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 4)
    
    local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = DropdownList; UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropdownList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end)
    
    Btn.MouseButton1Click:Connect(function()
        if not DropdownList.Visible then
            for _, v in pairs(DropdownList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            local Options = GetOptionsFunc()
            for _, opt in ipairs(Options) do
                local OptBtn = Instance.new("TextButton"); OptBtn.Parent = DropdownList; OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundTransparency = 1; OptBtn.Text = opt; OptBtn.TextColor3 = Color3.new(1,1,1); OptBtn.Font = Enum.Font.GothamSemibold; OptBtn.TextSize = 11; OptBtn.TextTruncate = Enum.TextTruncate.AtEnd; OptBtn.ZIndex = 101
                OptBtn.MouseButton1Click:Connect(function()
                    Btn.Text = opt; DropdownList.Visible = false
                    if Callback then Callback(opt) end
                end)
            end
        end
        DropdownList.Visible = not DropdownList.Visible
    end)
end

function CreateTileSelectorButton(Parent)
    local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 40); Btn.Text = "📝 Select Farm Tiles"; Btn.TextColor3 = Theme.Text; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.AutoButtonColor = true; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function()
        local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "KzoyzTileModal"; ScreenGui.Parent = game:GetService("CoreGui") or LP.PlayerGui
        local Overlay = Instance.new("TextButton"); Overlay.Parent = ScreenGui; Overlay.Size = UDim2.new(1, 0, 1, 0); Overlay.BackgroundColor3 = Color3.new(0,0,0); Overlay.BackgroundTransparency = 0.6; Overlay.Text = ""; Overlay.AutoButtonColor = false
        local Panel = Instance.new("Frame"); Panel.Parent = Overlay; Panel.BackgroundColor3 = Theme.DarkBlue; Panel.Size = UDim2.new(0, 260, 0, 340); Panel.Position = UDim2.new(0.5, 0, 0.5, 0); Panel.AnchorPoint = Vector2.new(0.5, 0.5); Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
        local Title = Instance.new("TextLabel"); Title.Parent = Panel; Title.Text = "Select Farm Tiles"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1
        local GridContainer = Instance.new("Frame"); GridContainer.Parent = Panel; GridContainer.Size = UDim2.new(0, 220, 0, 220); GridContainer.Position = UDim2.new(0.5, 0, 0, 45); GridContainer.AnchorPoint = Vector2.new(0.5, 0); GridContainer.BackgroundTransparency = 1
        local UIGrid = Instance.new("UIGridLayout"); UIGrid.Parent = GridContainer; UIGrid.CellSize = UDim2.new(0, 40, 0, 40); UIGrid.CellPadding = UDim2.new(0, 5, 0, 5); UIGrid.SortOrder = Enum.SortOrder.LayoutOrder
        
        local yLevels = {3, 2, 1, 0, -1}; local xLevels = {-2, -1, 0, 1, 2} 
        for _, y in ipairs(yLevels) do
            for _, x in ipairs(xLevels) do
                local Tile = Instance.new("TextButton"); Tile.Parent = GridContainer; Tile.Text = ""; Tile.Font = Enum.Font.GothamBold; Tile.TextSize = 10; Tile.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", Tile).CornerRadius = UDim.new(0, 8)
                if x == 0 and y == 0 then Tile.Text = "I'm Here" end 
                local isSelected = false
                for _, v in ipairs(getgenv().SelectedTiles) do if v.x == x and v.y == y then isSelected = true; break end end
                Tile.BackgroundColor3 = isSelected and Theme.TileOn or Theme.TileOff
                Tile.MouseButton1Click:Connect(function()
                    local foundIdx = nil
                    for i, v in ipairs(getgenv().SelectedTiles) do if v.x == x and v.y == y then foundIdx = i; break end end
                    if foundIdx then table.remove(getgenv().SelectedTiles, foundIdx); Tile.BackgroundColor3 = Theme.TileOff
                    else table.insert(getgenv().SelectedTiles, {x=x, y=y}); Tile.BackgroundColor3 = Theme.TileOn end
                end)
            end
        end
        local DoneBtn = Instance.new("TextButton"); DoneBtn.Parent = Panel; DoneBtn.BackgroundColor3 = Theme.TileYou; DoneBtn.Size = UDim2.new(0, 150, 0, 40); DoneBtn.Position = UDim2.new(0.5, 0, 1, -20); DoneBtn.AnchorPoint = Vector2.new(0.5, 1); DoneBtn.Text = "Done"; DoneBtn.TextColor3 = Color3.new(1,1,1); DoneBtn.Font = Enum.Font.GothamBold; DoneBtn.TextSize = 14; Instance.new("UICorner", DoneBtn).CornerRadius = UDim.new(0, 8)
        DoneBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    end)
end

-- [[ INJECT KE PAGE FARM ]] --
CreateToggle(PageFarm, "Auto Farm", "MasterAutoFarm") 
CreateDynamicDropdown(PageFarm, "Target Farm Block", "Auto (Equipped)", function()
    local opts = {"Auto (Equipped)"}
    for _, item in ipairs(ScanAvailableItems()) do table.insert(opts, item) end
    return opts
end, function(selected) getgenv().TargetFarmBlock = selected end)

CreateToggle(PageFarm, "Auto Collect", "AutoCollect") 
CreateToggle(PageFarm, "Only Collect Sapling", "AutoSaplingMode") 
CreateToggle(PageFarm, "Anti-AFK", "AntiAFK")
CreateInput(PageFarm, "Delay Collect (ms)", 250, "WaitDropMs") 
CreateInput(PageFarm, "Collect Speed (ms)", 100, "WalkSpeedMs") 
CreateInput(PageFarm, "Break Delay (ms)", 150, "BreakDelayMs") 
CreateInput(PageFarm, "Hit Count", 3, "HitCount") 
CreateTileSelectorButton(PageFarm) 

-- [[ INJECT KE PAGE SEED ]] --
CreateToggle(PageSeed, "Enable Auto Drop Sapling", "AutoDropSapling")
CreateInput(PageSeed, "Drop Threshold (Amount)", 50, "SaplingThreshold")

CreateDynamicDropdown(PageSeed, "Target Drop Seed", "Select Sapling...", function()
    return ScanAvailableItems()
end, function(selected) getgenv().TargetSaplingName = selected end)


-- [[ ========================================================= ]] --
-- [[ SYSTEM LOGIC (REMOTES & FARM LOOP) ]]
-- [[ ========================================================= ]] --
local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")
local RemoteDrop = Remotes:WaitForChild("PlayerDrop")

getgenv().KzoyzAntiAFK = LP.Idled:Connect(function()
    if getgenv().AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

getgenv().KzoyzHeartbeat = RunService.Heartbeat:Connect(function()
    if getgenv().AutoCollect then
        local highlights = workspace:FindFirstChild("TileHighligts") or workspace:FindFirstChild("TileHighlights")
        if highlights then pcall(function() highlights:ClearAllChildren() end) end
        if getgenv().IsGhosting then
            if getgenv().HoldCFrame then
                local char = LP.Character
                if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = getgenv().HoldCFrame end
            end
            if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true; PlayerMovement.Jumping = false end) end
        end
    end
end)

local function GetPlayerGridPosition()
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local ref = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if ref then return ref.Position.X, ref.Position.Y end
    return nil, nil
end

local function CheckDropsAtGrid(TargetGridX, TargetGridY)
    local TargetFolders = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
    local foundSapling = false; local foundAny = false
    for _, folder in ipairs(TargetFolders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                local pos = nil
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") then
                    local firstPart = obj:FindFirstChildWhichIsA("BasePart")
                    if firstPart then pos = firstPart.Position end
                end
                
                if pos then
                    local dX = math.floor(pos.X / getgenv().GridSize + 0.5)
                    local dY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                    
                    if dX == TargetGridX and dY == TargetGridY then
                        foundAny = true
                        local isSapling = false
                        for _, attrValue in pairs(obj:GetAttributes()) do
                            if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end
                        end
                        if not isSapling then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("StringValue") and string.find(string.lower(child.Value), "sapling") then isSapling = true; break end
                                for _, attrValue in pairs(child:GetAttributes()) do
                                    if type(attrValue) == "string" and string.find(string.lower(attrValue), "sapling") then isSapling = true; break end
                                end
                                if isSapling then break end
                            end
                        end
                        if isSapling then foundSapling = true end
                    end
                end
            end
        end
    end
    if getgenv().AutoSaplingMode then return foundSapling else return foundAny end
end

local function WalkGridSync(TargetX, TargetY)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if MyHitbox then
        local startZ = MyHitbox.Position.Z
        local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
        local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)
        
        while (currentX ~= TargetX or currentY ~= TargetY) and getgenv().MasterAutoFarm do
            if currentX ~= TargetX then currentX = currentX + (TargetX > currentX and 1 or -1) 
            elseif currentY ~= TargetY then currentY = currentY + (TargetY > currentY and 1 or -1) end
            local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
            MyHitbox.CFrame = CFrame.new(newWorldPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
            task.wait(getgenv().WalkSpeedMs / 1000) 
        end
    end
end

local function FindEmptyGridNearPlayer(BaseX, BaseY)
    local offsets = { {x=1, y=0}, {x=-1, y=0}, {x=0, y=1}, {x=0, y=-1}, {x=1, y=1}, {x=-1, y=-1}, {x=1, y=-1}, {x=-1, y=1}, {x=2, y=0}, {x=-2, y=0}, {x=0, y=2}, {x=0, y=-2} }
    for _, offset in ipairs(offsets) do
        local checkX = BaseX + offset.x; local checkY = BaseY + offset.y
        local isFarmTile = false
        for _, farmOffset in ipairs(getgenv().SelectedTiles) do if (BaseX + farmOffset.x) == checkX and (BaseY + farmOffset.y) == checkY then isFarmTile = true; break end end
        if not isFarmTile and not CheckDropsAtGrid(checkX, checkY) then return checkX, checkY end
    end
    return BaseX, BaseY 
end

-- Simpan Main Loop ke global variable
getgenv().KzoyzFarmLoop = task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm and InventoryMod then 
            local PosX, PosY = GetPlayerGridPosition()
            
            if PosX and PosY then 
                local BaseX = math.floor(PosX / getgenv().GridSize + 0.5)
                local BaseY = math.floor(PosY / getgenv().GridSize + 0.5)
                local ItemIndex 
                
                if getgenv().TargetFarmBlock and getgenv().TargetFarmBlock ~= "Auto (Equipped)" then
                    ItemIndex = GetSlotByItemID(getgenv().TargetFarmBlock)
                else
                    if getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                        _, ItemIndex = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule and getgenv().GameInventoryModule.GetSelectedItem then 
                        _, ItemIndex = getgenv().GameInventoryModule.GetSelectedItem() 
                    end 
                end
                
                if ItemIndex then
                    for _, offset in ipairs(getgenv().SelectedTiles) do 
                        if not getgenv().MasterAutoFarm then break end 
                        local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                        RemotePlace:FireServer(TGrid, ItemIndex); task.wait(getgenv().ActionDelay) 
                    end
                end

                for _, offset in ipairs(getgenv().SelectedTiles) do 
                    if not getgenv().MasterAutoFarm then break end 
                    local TGrid = Vector2.new(BaseX + offset.x, BaseY + offset.y) 
                    for hit = 1, getgenv().HitCount do 
                        if not getgenv().MasterAutoFarm then break end 
                        RemoteBreak:FireServer(TGrid); task.wait(getgenv().BreakDelayMs / 1000) 
                    end
                end
                
                if getgenv().AutoCollect then
                    task.wait(getgenv().WaitDropMs / 1000) 
                    local TilesToCollect = {}
                    for _, offset in ipairs(getgenv().SelectedTiles) do
                        local tx = BaseX + offset.x; local ty = BaseY + offset.y
                        if CheckDropsAtGrid(tx, ty) then table.insert(TilesToCollect, {x = tx, y = ty}) end
                    end
                    
                    if #TilesToCollect > 0 and getgenv().MasterAutoFarm then
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
                        
                        for _, tile in ipairs(TilesToCollect) do
                            if not getgenv().MasterAutoFarm then break end
                            WalkGridSync(tile.x, tile.y)
                            local waitTimeout = 0
                            while CheckDropsAtGrid(tile.x, tile.y) and waitTimeout < 15 and getgenv().MasterAutoFarm do task.wait(0.1); waitTimeout = waitTimeout + 1 end
                        end
                        
                        task.wait(0.1); WalkGridSync(BaseX, BaseY) 
                        
                        if hrp and ExactHrpCF then 
                            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
                            if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
                            hrp.CFrame = ExactHrpCF
                            if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityX = 0; PlayerMovement.VelocityY = 0; PlayerMovement.VelocityZ = 0; PlayerMovement.Grounded = true end) end
                            RunService.Heartbeat:Wait(); RunService.Heartbeat:Wait()
                            hrp.Anchored = false 
                            for _ = 1, 2 do if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end; RunService.Heartbeat:Wait() end
                        end
                        getgenv().IsGhosting = false 
                    end
                end
                
                if getgenv().AutoDropSapling and getgenv().TargetSaplingName ~= "Select Sapling..." then
                    local sapSlot = GetSlotByItemID(getgenv().TargetSaplingName)
                    local sapAmount = GetItemAmountByID(getgenv().TargetSaplingName)
                    
                    if sapSlot and sapAmount >= getgenv().SaplingThreshold then
                        local dropX, dropY = FindEmptyGridNearPlayer(BaseX, BaseY)
                        
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local HitboxFolder = workspace:FindFirstChild("Hitbox")
                        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
                        local ExactHrpCF = hrp and hrp.CFrame
                        local ExactHitboxCF = MyHitbox and MyHitbox.CFrame
                        local ExactPMPos = nil
                        if PlayerMovement then pcall(function() ExactPMPos = PlayerMovement.Position end) end

                        if hrp then getgenv().HoldCFrame = ExactHrpCF; hrp.Anchored = true; getgenv().IsGhosting = true end
                        
                        WalkGridSync(dropX, dropY)
                        task.wait(0.2)
                        
                        pcall(function() RemoteDrop:FireServer(sapSlot, sapAmount) end)
                        pcall(function() 
                            if UIManager and type(UIManager.FireEvent) == "function" then
                                UIManager:FireEvent("drp", { amt = tostring(sapAmount) })
                            else
                                local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent")
                                ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(sapAmount) } }}))
                            end
                        end)
                        
                        pcall(function()
                            if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
                            for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                                if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
                            end
                        end)
                        
                        task.wait(0.5); WalkGridSync(BaseX, BaseY)
                        
                        if hrp and ExactHrpCF then 
                            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
                            if MyHitbox and ExactHitboxCF then MyHitbox.CFrame = ExactHitboxCF; MyHitbox.AssemblyLinearVelocity = Vector3.zero end
                            hrp.CFrame = ExactHrpCF
                            if PlayerMovement and ExactPMPos then pcall(function() PlayerMovement.Position = ExactPMPos; PlayerMovement.OldPosition = ExactPMPos; PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end
                            RunService.Heartbeat:Wait(); hrp.Anchored = false 
                        end
                        getgenv().IsGhosting = false 
                    end
                end

            end 
        else 
            task.wait(0.1) 
        end 
    end 
end)
