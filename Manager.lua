-- [[ KZOYZ HUB - MANAGER MODULE (INJECTED) ]] --
local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

-- [[ FIX SCROLL MENTOK ]] --
TargetPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetPage.CanvasSize = UDim2.new(0, 0, 0, 0)
local listLayout = TargetPage:FindFirstChildWhichIsA("UIListLayout")
if listLayout then
    TargetPage.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TargetPage.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 30)
    end)
end
------------------------------

getgenv().ScriptVersion = "Manager v1.3-TrashUpdate" 

-- ========================================== --
getgenv().DropDelay = 2     
getgenv().TrashDelay = 2    
getgenv().StepDelay = 0.1   
getgenv().GridSize = 4.5 
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser") 

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

getgenv().AutoCollect = false
getgenv().AutoDrop = false
getgenv().AutoTrash = false
getgenv().DropAmount = 50
getgenv().TrashAmount = 50
getgenv().TargetPosX = 0
getgenv().TargetPosY = 0

-- Ambil UIManager buat bersihin sisa Prompt
local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

local function ManageUIState(Mode)
    local PG = LP:FindFirstChild("PlayerGui")
    if not PG then return end
    if Mode == "Normal" then
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = true end end end end
        local RestoredUI = {"GemsUI", "TopbarCentered", "TopbarCenteredClipped", "TopbarStandard", "TopbarStandardClipped", "ExperienceChat"}
        for _, name in pairs(RestoredUI) do local ui = PG:FindFirstChild(name); if ui and ui:IsA("ScreenGui") then ui.Enabled = true end end
    elseif Mode == "Dropping" then
        if PlayerMovement then PlayerMovement.InputActive = true end
        if PG:FindFirstChild("TouchGui") then PG.TouchGui.Enabled = true end
        if PG:FindFirstChild("InventoryUI") then PG.InventoryUI.Enabled = true end
        if PG:FindFirstChild("ExperienceChat") then PG.ExperienceChat.Enabled = true end
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end end end
    end
end

-- FUNGSI FORCE RESTORE UI DARI PABRIK
local function ForceRestoreUI()
    ManageUIState("Normal") 
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
    task.wait(0.1)
    pcall(function()
        if UIManager then
            if type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end
            if type(UIManager.ShowUI) == "function" then UIManager:ShowUI() end
        end
    end)
    pcall(function()
        local targetUIs = { "topbar", "gems", "playerui", "hotbar", "crosshair", "mainhud", "stats", "inventory", "backpack", "menu", "bottombar", "buttons" }
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") or gui:IsA("ScreenGui") or gui:IsA("ImageLabel") then
                local gName = string.lower(gui.Name)
                for _, tName in ipairs(targetUIs) do
                    if string.find(gName, tName) and not string.find(gName, "prompt") then
                        if gui:IsA("ScreenGui") then gui.Enabled = true else gui.Visible = true end
                    end
                end
            end
        end
    end)
end

local function FindInventoryModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindInventoryModule()

local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

function CreateToggle(Parent, Text, Var, OnToggle) local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false; local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Btn; local T = Instance.new("TextLabel"); T.Parent = Btn; T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame"); IndBg.Parent = Btn; IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(1,0); IC.Parent = IndBg; local Dot = Instance.new("Frame"); Dot.Parent = IndBg; Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner"); DC.CornerRadius = UDim.new(1,0); DC.Parent = Dot; Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end if OnToggle then OnToggle(getgenv()[Var]) end end) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Frame; local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox"); InputBox.Parent = Frame; InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); local IC = Instance.new("UICorner"); IC.CornerRadius = UDim.new(0, 4); IC.Parent = InputBox; InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner"); C.CornerRadius = UDim.new(0, 6); C.Parent = Btn; Btn.MouseButton1Click:Connect(Callback) end

-- ========================================== --
-- [[ BIKIN UI MANAGER ]]
-- ========================================== --
CreateToggle(TargetPage, "📍 Enable Auto Collect", "AutoCollect")
local BoxX = CreateTextBox(TargetPage, "Target Grid X", 0, "TargetPosX")
local BoxY = CreateTextBox(TargetPage, "Target Grid Y", 0, "TargetPosY")
CreateButton(TargetPage, "📍 Save Pos (Current Loc)", function()
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    local RefPart = MyHitbox or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if RefPart then
        local currX = math.floor(RefPart.Position.X / getgenv().GridSize + 0.5)
        local currY = math.floor(RefPart.Position.Y / getgenv().GridSize + 0.5)
        getgenv().TargetPosX = currX; getgenv().TargetPosY = currY
        BoxX.Text = tostring(currX); BoxY.Text = tostring(currY)
    end
end)

-- AUTO DROP UI
CreateToggle(TargetPage, "📦 Auto Drop", "AutoDrop", function(state) 
    if not state then ForceRestoreUI() end 
end)
CreateTextBox(TargetPage, "📦 Drop Amount", 50, "DropAmount") -- Dulu pakai CreateSlider

-- AUTO TRASH UI
CreateToggle(TargetPage, "🚮 Auto Trash", "AutoTrash", function(state) 
    if not state then ForceRestoreUI() end 
end)
CreateTextBox(TargetPage, "🗑️ Trash Amount", 50, "TrashAmount")

-- ========================================== --
-- [[ REMOTES & EVENTS ]]
-- ========================================== --
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local RemoteTrashSafe = Remotes:WaitForChild("PlayerItemTrash") -- Remote buat trashing
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 

RunService.RenderStepped:Connect(function() 
    if getgenv().AutoDrop or getgenv().AutoTrash then 
        ManageUIState("Dropping") -- Pakai mode yang sama buat hide UI
    end 
end)

-- [[ LOGIKA AUTO DROP (Dengan State Tracker) ]]
task.spawn(function() 
    local WasAutoDropOn = false
    while true do 
        if getgenv().AutoDrop then 
            WasAutoDropOn = true
            local Amt = getgenv().DropAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                        _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then 
                        _, slot = getgenv().GameInventoryModule.GetSelectedItem() 
                    end; 
                    if slot then RemoteDropSafe:FireServer(slot, Amt) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(Amt) } }})) end)
            
            pcall(function()
                for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                    if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
                end
            end)
            
            task.wait(getgenv().DropDelay) 
        else
            if WasAutoDropOn then WasAutoDropOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO TRASH (Dengan State Tracker) ]]
task.spawn(function() 
    local WasAutoTrashOn = false
    while true do 
        if getgenv().AutoTrash then 
            WasAutoTrashOn = true
            local Amt = getgenv().TrashAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                        _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then 
                        _, slot = getgenv().GameInventoryModule.GetSelectedItem() 
                    end; 
                    -- Remote Trash CUMA BUHUT SLOT AJA (Sesuai script kamu: args = { 19 })
                    if slot then RemoteTrashSafe:FireServer(slot) end 
                end 
            end); 
            task.wait(0.2)
            -- Konfirmasi Trash dengan Amount ke UIManager (Sesuai script kamu: ButtonAction = "trsh")
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "trsh", Inputs = { amt = tostring(Amt) } }})) end)
            
            pcall(function()
                for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
                    if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
                end
            end)
            
            task.wait(getgenv().TrashDelay) 
        else
            if WasAutoTrashOn then WasAutoTrashOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO COLLECT GRID ]]
task.spawn(function() while true do if getgenv().AutoCollect then local HitboxFolder = workspace:FindFirstChild("Hitbox"); local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name); if MyHitbox then local startZ = MyHitbox.Position.Z; local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5); local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5); local homeX = currentX; local homeY = currentY; local targetX = getgenv().TargetPosX; local targetY = getgenv().TargetPosY; if currentX ~= targetX or currentY ~= targetY then local function WalkGrid(tX, tY) while (currentX ~= tX or currentY ~= tY) and getgenv().AutoCollect do if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1) elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end; local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ); MyHitbox.CFrame = CFrame.new(newWorldPos); if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end; task.wait(getgenv().StepDelay) end end; WalkGrid(targetX, targetY); task.wait(0.6); WalkGrid(homeX, homeY) end end end; task.wait(2) end end)
