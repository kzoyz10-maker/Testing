-- [[ ========================================================= ]] --
-- [[ KZOYZ HUB - MASTER AUTO FARM & COLLECT (SYNCED LOOP)      ]] --
-- [[ ========================================================= ]] --

local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

getgenv().ScriptVersion = "Auto Farm v7.0 (Master Loop)" 

-- ========================================== --
getgenv().ActionDelay = 0.15 -- Cooldown mutlak server game
getgenv().GridSize = 4.5 
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser") 

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

getgenv().MasterAutoFarm = false; -- 🌟 TOGGLE UTAMA DISEKUENS (PLACE + BREAK)
getgenv().AutoCollect = false; 
getgenv().OffsetX = 0; 
getgenv().OffsetY = 0; 
getgenv().FarmAmount = 1; 
getgenv().HitCount = 3    

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
CreateToggle(TargetPage, "Master Auto Farm", "MasterAutoFarm") -- Menyatukan Place & Break
CreateToggle(TargetPage, "Auto Collect", "AutoCollect")
CreateSlider(TargetPage, "Farm Offset X", -5, 5, 0, "OffsetX")
CreateSlider(TargetPage, "Farm Offset Y", -5, 5, 0, "OffsetY")
CreateSlider(TargetPage, "Farm Amount", 1, 5, 1, "FarmAmount")
CreateSlider(TargetPage, "Hit Count", 1, 15, 3, "HitCount") 

local Remotes = RS:WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteBreak = Remotes:WaitForChild("PlayerFist")

local function GetPlayerGridPosition()
    if PlayerMovement and PlayerMovement.Position then return PlayerMovement.Position.X, PlayerMovement.Position.Y else local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if hrp then return hrp.Position.X, hrp.Position.Y end end return nil, nil
end

-- 🌟 1. LOOP MASTER AUTO FARM (SINKRON!)
task.spawn(function() 
    while true do 
        if getgenv().MasterAutoFarm and getgenv().GameInventoryModule then 
            local PosX, PosY = GetPlayerGridPosition()
            
            if PosX and PosY then 
                local X = math.floor(PosX / getgenv().GridSize + 0.5)
                local Y = math.floor(PosY / getgenv().GridSize + 0.5)
                local _, ItemIndex 
                
                if getgenv().GameInventoryModule.GetSelectedHotbarItem then 
                    _, ItemIndex = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                elseif getgenv().GameInventoryModule.GetSelectedItem then 
                    _, ItemIndex = getgenv().GameInventoryModule.GetSelectedItem() 
                end 
                
                if ItemIndex then 
                    for i = 0, getgenv().FarmAmount - 1 do 
                        if not getgenv().MasterAutoFarm then break end 
                        local TGrid = Vector2.new(X + getgenv().OffsetX + i, Y + getgenv().OffsetY) 
                        
                        -- LANGKAH A: PLACE ITEM
                        RemotePlace:FireServer(TGrid, ItemIndex) 
                        task.wait(getgenv().ActionDelay) -- Tunggu server merespons
                        
                        -- LANGKAH B: BREAK ITEM (Dipukul HitCount kali)
                        for hit = 1, getgenv().HitCount do 
                            if not getgenv().MasterAutoFarm then break end 
                            RemoteBreak:FireServer(TGrid) 
                            task.wait(getgenv().ActionDelay) -- Tunggu server merespons
                        end
                    end 
                else
                    -- Jika item kosong, jalankan Break saja sebagai cadangan
                    for i = 0, getgenv().FarmAmount - 1 do 
                        if not getgenv().MasterAutoFarm then break end 
                        local TGrid = Vector2.new(X + getgenv().OffsetX + i, Y + getgenv().OffsetY) 
                        for hit = 1, getgenv().HitCount do 
                            if not getgenv().MasterAutoFarm then break end 
                            RemoteBreak:FireServer(TGrid) 
                            task.wait(getgenv().ActionDelay)
                        end
                    end
                end 
            end 
        else 
            task.wait(0.1) 
        end 
    end 
end)

-- 2. LOOP AUTO COLLECT
task.spawn(function()
    while true do
        if getgenv().AutoCollect then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dropFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items") or workspace:FindFirstChild("DroppedItems")
                if dropFolder then
                    for _, drop in pairs(dropFolder:GetDescendants()) do
                        if drop:IsA("BasePart") then drop.CFrame = hrp.CFrame end
                    end
                else
                    for _, obj in pairs(workspace:GetChildren()) do
                        if obj:IsA("BasePart") and not obj.Anchored and obj.Name ~= "Baseplate" then obj.CFrame = hrp.CFrame
                        elseif obj:IsA("Model") and (obj.Name:match("Drop") or obj.Name:match("Item")) and obj.PrimaryPart then obj:SetPrimaryPartCFrame(hrp.CFrame) end
                    end
                end
            end
        end
        task.wait(0.1) 
    end
end)
