-- [[ ========================================================= ]] --
-- [[ KZOYZ HUB - MASTER AUTO FARM & TRUE GHOST COLLECT (v8.9)  ]] --
-- [[ ========================================================= ]] --

local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

getgenv().ScriptVersion = "Auto Farm v8.9 (No Jump Ghost)" 

-- ========================================== --
getgenv().ActionDelay = 0.15 
getgenv().GridSize = 4.5 
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser") 
local RunService = game:GetService("RunService")

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

getgenv().MasterAutoFarm = false; 
getgenv().AutoCollect = false; 
getgenv().OffsetX = 0; 
getgenv().OffsetY = 0; 
getgenv().FarmAmount = 1; 
getgenv().HitCount = 3;
getgenv().BreakDelayMs = 150; 
getgenv().WaitDropMs = 250;  
getgenv().WalkSpeedMs = 100; 

-- Variabel Ghosting
getgenv().IsGhosting = false
getgenv().HoldCFrame = nil

local PlayerMovement
task.spawn(function() pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end) end)

local function FindInventoryModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindInventoryModule()

-- UI Theme
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton"); Btn.Parent = Parent; Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local T = Instance.new("TextLabel"); T.Parent = Btn; T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame"); IndBg.Parent = Btn; IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); Instance.new("UICorner", IndBg).CornerRadius = UDim.new(1,0)
    local Dot = Instance.new("Frame"); Dot.Parent = IndBg; Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
    Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) 
end

function CreateSlider(Parent, Text, Min, Max, Default, Var) 
    local Frame = Instance.new("Frame"); Frame.Parent = Parent; Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 45); Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel"); Label.Parent = Frame; Label.Text = Text .. ": " .. Default; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 20); Label.Position = UDim2.new(0, 10, 0, 2); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; 
    local SliderBg = Instance.new("TextButton"); SliderBg.Parent = Frame; SliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SliderBg.Position = UDim2.new(0, 10, 0, 28); SliderBg.Size = UDim2.new(1, -20, 0, 6); SliderBg.Text = ""; SliderBg.AutoButtonColor = false; Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1,0)
    local Fill = Instance.new("Frame"); Fill.Parent = SliderBg; Fill.BackgroundColor3 = Theme.Purple; Fill.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0); Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
    local Dragging = false; 
    local function Update(input) local SizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1); local Val = math.floor(Min + ((Max - Min) * SizeX)); Fill.Size = UDim2.new(SizeX, 0, 1, 0); Label.Text = Text .. ": " .. Val; getgenv()[Var] = Val end; 
    SliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = true; Update(i) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dragging = false end end); UIS.InputChanged:Connect(function(i) if Dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Update(i) end end) 
end

-- Inject elemen ke UI
CreateToggle(TargetPage, "Master Auto Farm", "MasterAutoFarm") 
CreateToggle(TargetPage, "👻 Smart Auto Collect (Ghost)", "AutoCollect") 
CreateSlider(TargetPage, "Wait Drop (ms)", 50, 1000, 250, "WaitDropMs") 
CreateSlider(TargetPage, "Walk Speed (ms)", 10, 500, 100, "WalkSpeedMs") 
CreateSlider(TargetPage, "Break Delay (ms)", 10, 500, 150, "BreakDelayMs") 
CreateSlider(TargetPage, "Farm Offset X", -5, 5, 0, "OffsetX")
CreateSlider(TargetPage, "Farm Offset Y", -5, 5, 0, "OffsetY")
CreateSlider(TargetPage, "Farm Amount", 1, 5, 1, "FarmAmount")
CreateSlider(TargetPage, "Hit Count", 1, 15, 3, "HitCount") 

local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")

-- 🌟 KUNCI POSISI CADANGAN
RunService.Heartbeat:Connect(function()
    if getgenv().AutoCollect and getgenv().IsGhosting and getgenv().HoldCFrame then
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = getgenv().HoldCFrame
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
                    if dX == TargetGridX and dY == TargetGridY then return true end
                end
            end
        end
    end
    return false
end

-- 🌟 FUNGSI JALAN PER GRID
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
            
            if PlayerMovement then 
                pcall(function() PlayerMovement.Position = newWorldPos end) 
            end
            
            task.wait(getgenv().WalkSpeedMs / 1000) 
        end
    end
end

-- 🌟 LOOP SINKRONISASI UTAMA
task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm and getgenv().GameInventoryModule then 
            local PosX, PosY = GetPlayerGridPosition()
            
            if PosX and PosY then 
                local BaseX = math.floor(PosX / getgenv().GridSize + 0.5)
                local BaseY = math.floor(PosY / getgenv().GridSize + 0.5)
                local _, ItemIndex 
                
                if getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                    _, ItemIndex = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                elseif getgenv().GameInventoryModule.GetSelectedItem then 
                    _, ItemIndex = getgenv().GameInventoryModule.GetSelectedItem() 
                end 
                
                for i = 0, getgenv().FarmAmount - 1 do 
                    if not getgenv().MasterAutoFarm then break end 
                    
                    local TargetGridX = BaseX + getgenv().OffsetX + i
                    local TargetGridY = BaseY + getgenv().OffsetY
                    local TGrid = Vector2.new(TargetGridX, TargetGridY) 
                    
                    if ItemIndex then RemotePlace:FireServer(TGrid, ItemIndex); task.wait(getgenv().ActionDelay) end
                    
                    for hit = 1, getgenv().HitCount do 
                        if not getgenv().MasterAutoFarm then break end 
                        RemoteBreak:FireServer(TGrid); task.wait(getgenv().BreakDelayMs / 1000) 
                    end
                    
                    -- C. SMART AUTO COLLECT (GHOSTING + NO JUMP FIX)
                    if getgenv().AutoCollect then
                        task.wait(getgenv().WaitDropMs / 1000) 
                        
                        if CheckDropsAtGrid(TargetGridX, TargetGridY) then
                            
                            -- 🌟 1. BEKUKAN KARAKTER VISUAL SECARA TOTAL 🌟
                            local char = LP.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local animate = char and char:FindFirstChild("Animate")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            
                            if hrp then
                                getgenv().HoldCFrame = hrp.CFrame
                                hrp.Anchored = true 
                                getgenv().IsGhosting = true 
                            end
                            
                            if animate then 
                                animate.Disabled = true 
                            end
                            
                            if hum then
                                -- Mencegah engine Roblox memicu animasi lompat/jatuh
                                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                                hum.Jump = false
                                
                                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                                    track:Stop()
                                end
                            end
                            
                            -- 🌟 2. BERANGKATKAN HITBOX KE BARANG 🌟
                            WalkGridSync(TargetGridX, TargetGridY)
                            
                            local waitTimeout = 0
                            while CheckDropsAtGrid(TargetGridX, TargetGridY) and waitTimeout < 15 and getgenv().MasterAutoFarm do
                                task.wait(0.1); waitTimeout = waitTimeout + 1
                            end
                            
                            -- 🌟 3. BALIKKAN HITBOX KE BASE 🌟
                            task.wait(0.1)
                            WalkGridSync(BaseX, BaseY)
                            task.wait(0.1)
                            
                            -- 🌟 4. LEPASKAN KUNCIAN VISUAL 🌟
                            if hrp then hrp.Anchored = false end
                            if animate then animate.Disabled = false end
                            if hum then 
                                -- Kembalikan state lompat/jatuh biar normal lagi
                                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                            end
                            getgenv().IsGhosting = false 
                        end
                    end
                end 
            end 
        else 
            task.wait(0.1) 
        end 
    end 
end)
