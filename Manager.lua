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

getgenv().ScriptVersion = "Manager v2.3-AutoStaffDetect+Zoom" 

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

-- Variabel Auto Chat 
getgenv().AutoChat = false
getgenv().ChatText = "Halo Semuanya"
getgenv().ChatDelay = 3
getgenv().ChatRandomLetter = true

-- Variabel Streamer Mode, Security & Zoom
getgenv().HideName = false
getgenv().FakeNameText = "KzoyzPlayer"
getgenv().AntiStaff = false
getgenv().CustomZoom = 1000

-- Ambil UIManager
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

-- [[ UI COMPONENT BUILDERS (COMPACTED) ]]
function CreateAccordion(Parent, Title, DefaultState)
    local Frame = Instance.new("Frame", Parent); Frame.BackgroundTransparency = 1; Frame.Size = UDim2.new(1, -10, 0, 0); Frame.AutomaticSize = Enum.AutomaticSize.Y
    local Layout = Instance.new("UIListLayout", Frame); Layout.SortOrder = Enum.SortOrder.LayoutOrder; Layout.Padding = UDim.new(0, 5)
    local Btn = Instance.new("TextButton", Frame); Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); Btn.Size = UDim2.new(1, 0, 0, 35); Btn.Text = "  " .. Title; Btn.TextColor3 = Color3.fromRGB(255, 215, 0); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local Icon = Instance.new("TextLabel", Btn); Icon.BackgroundTransparency = 1; Icon.Size = UDim2.new(0, 30, 1, 0); Icon.Position = UDim2.new(1, -30, 0, 0); Icon.Text = DefaultState and "v" or ">"; Icon.TextColor3 = Color3.new(1,1,1); Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 14
    local Content = Instance.new("Frame", Frame); Content.BackgroundTransparency = 1; Content.Size = UDim2.new(1, 0, 0, 0); Content.AutomaticSize = Enum.AutomaticSize.Y; Content.Visible = DefaultState; local CLayout = Instance.new("UIListLayout", Content); CLayout.SortOrder = Enum.SortOrder.LayoutOrder; CLayout.Padding = UDim.new(0, 5)
    local isOpen = DefaultState
    Btn.MouseButton1Click:Connect(function() isOpen = not isOpen; Content.Visible = isOpen; Icon.Text = isOpen and "v" or ">" end)
    return Content
end

function CreateToggle(Parent, Text, Var, OnToggle) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, 0, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); Instance.new("UICorner", IndBg).CornerRadius = UDim.new(1,0)
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
    IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30)
    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]
        if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple 
        else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end 
        if OnToggle then OnToggle(getgenv()[Var]) end 
    end) 
end

function CreateTextBox(Parent, Text, Default, Var) 
    local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, 0, 0, 35); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame); Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left
    local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 4)
    getgenv()[Var] = Default
    InputBox.FocusLost:Connect(function() 
        if type(Default) == "number" then local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end 
        else getgenv()[Var] = InputBox.Text end
    end)
    return InputBox 
end

function CreateButton(Parent, Text, Callback) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, 0, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) 
end

-- ========================================== --
-- [[ SISTEM DUAL TAB ]]
-- ========================================== --
local TabNav = Instance.new("Frame", TargetPage); TabNav.Size = UDim2.new(1, -10, 0, 35); TabNav.BackgroundTransparency = 1
local TabMgrBtn = Instance.new("TextButton", TabNav); TabMgrBtn.Size = UDim2.new(0.48, 0, 1, 0); TabMgrBtn.BackgroundColor3 = Theme.Purple; TabMgrBtn.Text = "Menu Manager"; TabMgrBtn.TextColor3 = Theme.Text; TabMgrBtn.Font = Enum.Font.GothamBold; TabMgrBtn.TextSize = 12; Instance.new("UICorner", TabMgrBtn).CornerRadius = UDim.new(0, 6)
local TabChatBtn = Instance.new("TextButton", TabNav); TabChatBtn.Size = UDim2.new(0.48, 0, 1, 0); TabChatBtn.Position = UDim2.new(0.52, 0, 0, 0); TabChatBtn.BackgroundColor3 = Theme.Item; TabChatBtn.Text = "Spam Chat"; TabChatBtn.TextColor3 = Theme.Text; TabChatBtn.Font = Enum.Font.GothamBold; TabChatBtn.TextSize = 12; Instance.new("UICorner", TabChatBtn).CornerRadius = UDim.new(0, 6)

local PageManager = Instance.new("Frame", TargetPage); PageManager.Size = UDim2.new(1, 0, 0, 0); PageManager.BackgroundTransparency = 1; PageManager.AutomaticSize = Enum.AutomaticSize.Y; local UIListManager = Instance.new("UIListLayout", PageManager); UIListManager.Padding = UDim.new(0, 5)
local PageChat = Instance.new("Frame", TargetPage); PageChat.Size = UDim2.new(1, 0, 0, 0); PageChat.BackgroundTransparency = 1; PageChat.AutomaticSize = Enum.AutomaticSize.Y; PageChat.Visible = false; local UIListChat = Instance.new("UIListLayout", PageChat); UIListChat.Padding = UDim.new(0, 5)

TabMgrBtn.MouseButton1Click:Connect(function() PageManager.Visible = true; PageChat.Visible = false; TabMgrBtn.BackgroundColor3 = Theme.Purple; TabChatBtn.BackgroundColor3 = Theme.Item end)
TabChatBtn.MouseButton1Click:Connect(function() PageManager.Visible = false; PageChat.Visible = true; TabMgrBtn.BackgroundColor3 = Theme.Item; TabChatBtn.BackgroundColor3 = Theme.Purple end)

-- ========================================== --
-- [[ ISI UI PAGE MANAGER (DROPDOWNS) ]]
-- ========================================== --

-- 1. ACCORDION SECURITY (AUTO DETECT STAFF)
local AccSec = CreateAccordion(PageManager, "🛡️ Security (Auto Detect Staff)", true)
CreateToggle(AccSec, "▶ Enable Anti-Staff Auto Disconnect", "AntiStaff")

-- 2. ACCORDION CAMERA ZOOM
local AccCam = CreateAccordion(PageManager, "🎥 Camera Custom Zoom", false)
CreateTextBox(AccCam, "Max Zoom Distance", 1000, "CustomZoom")
CreateButton(AccCam, "Apply Camera Zoom", function()
    pcall(function()
        LP.CameraMaxZoomDistance = tonumber(getgenv().CustomZoom) or 1000
        LP.CameraMinZoomDistance = 0.5 
    end)
end)

-- 3. ACCORDION AUTO COLLECT
local AccCollect = CreateAccordion(PageManager, "⚙️ Auto Collect Settings", false)
CreateToggle(AccCollect, "▶ Enable Auto Collect", "AutoCollect")
local BoxX = CreateTextBox(AccCollect, "Target Grid X", 0, "TargetPosX")
local BoxY = CreateTextBox(AccCollect, "Target Grid Y", 0, "TargetPosY")
CreateButton(AccCollect, "📍 Save Pos (Current Loc)", function()
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

-- 4. ACCORDION AUTO DROP
local AccDrop = CreateAccordion(PageManager, "📦 Auto Drop Settings", false)
CreateToggle(AccDrop, "▶ Enable Auto Drop", "AutoDrop", function(state) if not state then ForceRestoreUI() end end)
CreateTextBox(AccDrop, "Drop Amount", 50, "DropAmount")
CreateTextBox(AccDrop, "Drop Delay (Detik)", 2, "DropDelay") 

-- 5. ACCORDION AUTO TRASH
local AccTrash = CreateAccordion(PageManager, "🚮 Auto Trash Settings", false)
CreateToggle(AccTrash, "▶ Enable Auto Trash", "AutoTrash", function(state) if not state then ForceRestoreUI() end end)
CreateTextBox(AccTrash, "Trash Amount", 50, "TrashAmount")
CreateTextBox(AccTrash, "Trash Delay (Detik)", 2, "TrashDelay") 


-- 7. ACCORDION STREAMER MODE
local AccStreamer = CreateAccordion(PageManager, "👁️ Streamer Mode (Spoof Name)", false)
CreateToggle(AccStreamer, "▶ Enable Spoof Name", "HideName")
CreateTextBox(AccStreamer, "Custom Fake Name", "KzoyzPlayer", "FakeNameText")

-- ========================================== --
-- [[ ISI UI PAGE AUTO CHAT ]]
-- ========================================== --
local AccChat = CreateAccordion(PageChat, "💬 Auto Spam Chat Settings", true)
CreateToggle(AccChat, "▶ Enable Auto Chat", "AutoChat")
CreateTextBox(AccChat, "Pesan Chat", "Jual barang di world sini", "ChatText")
CreateTextBox(AccChat, "Delay (Detik)", 3, "ChatDelay")
CreateToggle(AccChat, "Anti Spam (Huruf Random)", "ChatRandomLetter")

-- ========================================== --
-- [[ REMOTES & EVENTS ]]
-- ========================================== --
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local RemoteTrashSafe = Remotes:WaitForChild("PlayerItemTrash") 
local RemoteInspect = Remotes:WaitForChild("PlayerInspectPlayer") 
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 
local ChatRemote = RS:WaitForChild("CB")

RunService.RenderStepped:Connect(function() if getgenv().AutoDrop or getgenv().AutoTrash then ManageUIState("Dropping") end end)

-- [[ LOGIKA ANTI-STAFF (SMART AUTO DETECT) ]]
local function CheckIfStaff(player)
    if not getgenv().AntiStaff then return end
    if player == LP then return end
    
    task.spawn(function()
        pcall(function()
            local isStaff = false
            
            -- 1. Deteksi Jika Creator Asli Game Masuk
            if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
                isStaff = true
            end
            
            -- 2. Deteksi Jika Game Dibikin Oleh Grup & Pangkat Player Tersebut Tinggi (Mod/Admin/Dev)
            if game.CreatorType == Enum.CreatorType.Group then
                local playerRank = player:GetRankInGroup(game.CreatorId)
                if playerRank >= 100 then -- Rank 100+ biasanya Moderator ke atas
                    isStaff = true
                end
            end
            
            -- 3. Deteksi Jika Player Punya Role Official Roblox Admin (Grup ID 1200769)
            if player:GetRankInGroup(1200769) > 0 then
                isStaff = true
            end
            
            -- EKSEKUSI AUTO KICK
            if isStaff then
                LP:Kick("🛡️ Kzoyz Security: Auto Disconnect!\n\nModerator/Developer (" .. player.Name .. ") terdeteksi memasuki server.")
            end
        end)
    end)
end

Players.PlayerAdded:Connect(function(newPlayer) 
    CheckIfStaff(newPlayer)
    if getgenv().AutoBan then ExecuteBan(newPlayer) end 
end)

task.spawn(function()
    while true do
        if getgenv().AntiStaff then
            for _, p in ipairs(Players:GetPlayers()) do CheckIfStaff(p) end
        end
        task.wait(2)
    end
end)


-- [[ LOGIKA STREAMER MODE / SPOOF NAME ]]
task.spawn(function()
    local realName = LP.Name
    local realDisplay = LP.DisplayName
    local activeFake = realName
    
    while true do
        local targetName = realName
        local targetDisplay = realDisplay
        if getgenv().HideName then
            local f = getgenv().FakeNameText
            targetName = (f == "" or f == " ") and "HiddenPlayer" or f
            targetDisplay = targetName
        end
        
        local function ReplaceSafe(obj)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local txt = obj.Text
                local changed = false
                if targetName ~= realName and txt:find(realName) then txt = string.gsub(txt, realName, targetName); changed = true end
                if targetDisplay ~= realDisplay and txt:find(realDisplay) then txt = string.gsub(txt, realDisplay, targetDisplay); changed = true end
                if activeFake ~= targetName and activeFake ~= realName and activeFake ~= realDisplay then
                    if txt:find(activeFake) then txt = string.gsub(txt, activeFake, targetName); changed = true end
                end
                if changed and obj.Text ~= txt then obj.Text = txt end
            end
        end
        
        if LP.Character then for _, v in pairs(LP.Character:GetDescendants()) do ReplaceSafe(v) end end
        if LP:FindFirstChild("PlayerGui") then for _, v in pairs(LP.PlayerGui:GetDescendants()) do ReplaceSafe(v) end end
        activeFake = targetName
        task.wait(1) 
    end
end)

-- [[ LOGIKA AUTO CHAT SPAM ]]
task.spawn(function()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    while true do
        if getgenv().AutoChat then
            local currentMsg = getgenv().ChatText
            if getgenv().ChatRandomLetter then
                local rand = math.random(1, #charset)
                local rChar = string.sub(charset, rand, rand)
                currentMsg = currentMsg .. " [" .. rChar .. "]"
            end
            pcall(function() ChatRemote:FireServer(currentMsg) end)
            task.wait(getgenv().ChatDelay) 
        else
            task.wait(0.5)
        end
    end
end)



-- [[ LOGIKA AUTO DROP ]]
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
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().DropDelay) 
        else
            if WasAutoDropOn then WasAutoDropOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO TRASH ]]
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
                    if slot then RemoteTrashSafe:FireServer(slot) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "trsh", Inputs = { amt = tostring(Amt) } }})) end)
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().TrashDelay)
        else
            if WasAutoTrashOn then WasAutoTrashOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

-- [[ LOGIKA AUTO COLLECT GRID (ANTI-POTONG) ]]
task.spawn(function() 
    while true do 
        if getgenv().AutoCollect then 
            local HitboxFolder = workspace:FindFirstChild("Hitbox")
            local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
            if MyHitbox then 
                local startZ = MyHitbox.Position.Z
                local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
                local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)
                local homeX = currentX
                local homeY = currentY
                local targetX = getgenv().TargetPosX
                local targetY = getgenv().TargetPosY
                if currentX ~= targetX or currentY ~= targetY then 
                    local function WalkGrid(tX, tY) 
                        while (currentX ~= tX or currentY ~= tY) and getgenv().AutoCollect do 
                            if currentX ~= tX then 
                                currentX = currentX + (tX > currentX and 1 or -1) 
                            elseif currentY ~= tY then 
                                currentY = currentY + (tY > currentY and 1 or -1) 
                            end
                            local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
                            MyHitbox.CFrame = CFrame.new(newWorldPos)
                            if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
                            task.wait(getgenv().StepDelay) 
                        end 
                    end
                    WalkGrid(targetX, targetY)
                    task.wait(0.6)
                    WalkGrid(homeX, homeY) 
                end 
            end 
        end
        task.wait(2) 
    end 
end)
