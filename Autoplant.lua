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

getgenv().ScriptVersion = "Auto Farm v9 (String Format Fix)"

-- ========================================== --
-- [[ KONFIGURASI UTAMA ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().StepDelay = 0.08   
getgenv().PlaceDelay = 0.15  
getgenv().BreakDelay = 0.15  

getgenv().EnableAutoPlant = false
getgenv().EnableAutoBreak = false

getgenv().FarmStartX = 0
getgenv().FarmEndX = 50
getgenv().FarmStartY = 37    
getgenv().FarmEndY = 10      
getgenv().FarmStepY = 2      

getgenv().SelectedSeed = ""
getgenv().HitsPerBlock = 1   

-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local function GetSlotByItemID(targetID)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) and data.Amount > 0 then return slotIndex end
    end return nil
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
    if #items == 0 then items = {"Kosong"} end return items
end

-- ========================================== --
-- [[ UI SETUP ]]
-- ========================================== --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255), Red = Color3.fromRGB(255, 80, 80) }

function CreateToggle(Parent, Text, Var, IsBreak) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = "  " .. Text; Btn.TextColor3 = Theme.Text; Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 12; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 
    local activeColor = IsBreak and Theme.Red or Theme.Purple

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then
            if IsBreak then getgenv().EnableAutoPlant = false else getgenv().EnableAutoBreak = false end
        end
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = activeColor 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Btn.MouseButton1Click:Connect(Callback) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local Label = Instance.new("TextLabel", Frame); Label.Text = "  "..Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text) or InputBox.Text; getgenv()[Var] = val; InputBox.Text = tostring(getgenv()[Var]) end); return InputBox end
function CreateDropdown(Parent, Text, DefaultOptions, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""; local Label = Instance.new("TextLabel", TopBtn); Label.Text = "  " .. Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; local List = Instance.new("UIListLayout", Scroll); local isOpen = false; TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true) else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true) end end); local function RefreshOptions(Options) for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end; for _, opt in ipairs(Options) do local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11; OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = "  " .. Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true) end) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) end; RefreshOptions(DefaultOptions); return RefreshOptions end

-- [[ INJECT MENU ]]
local RefreshSeedDropdown = CreateDropdown(TargetPage, "Pilih Seed (Buat Plant)", ScanAvailableItems(), "SelectedSeed")
CreateButton(TargetPage, "🔄 Refresh Tas", function() RefreshSeedDropdown(ScanAvailableItems()) end)

CreateTextBox(TargetPage, "X Kiri (Start)", getgenv().FarmStartX, "FarmStartX")
CreateTextBox(TargetPage, "X Kanan (End)", getgenv().FarmEndX, "FarmEndX")
CreateTextBox(TargetPage, "Y Atas (Mulai)", getgenv().FarmStartY, "FarmStartY")
CreateTextBox(TargetPage, "Y Bawah (Berhenti)", getgenv().FarmEndY, "FarmEndY")
CreateTextBox(TargetPage, "Turun Tiap (Y Step)", getgenv().FarmStepY, "FarmStepY")
CreateTextBox(TargetPage, "Hit Per Blok (Break)", getgenv().HitsPerBlock, "HitsPerBlock")

CreateToggle(TargetPage, "🚜 START AUTO PLANT", "EnableAutoPlant", false)
CreateToggle(TargetPage, "🔨 START AUTO HARVEST", "EnableAutoBreak", true)

-- ========================================== --
-- [[ SISTEM FULL MODFLY ]]
-- ========================================== --
if getgenv().KzoyzModFlyHeartbeat then getgenv().KzoyzModFlyHeartbeat:Disconnect(); getgenv().KzoyzModFlyHeartbeat = nil end
if workspace:FindFirstChild("KzoyzAirWalk") then workspace.KzoyzAirWalk:Destroy() end

local AirPlat = Instance.new("Part")
AirPlat.Name = "KzoyzAirWalk"
AirPlat.Size = Vector3.new(getgenv().GridSize + 1, 1, getgenv().GridSize + 1)
AirPlat.Anchored = true; AirPlat.CanCollide = true; AirPlat.Transparency = 1 
AirPlat.Parent = workspace
getgenv().AirPlatform = AirPlat

getgenv().KzoyzModFlyHeartbeat = RunService.Heartbeat:Connect(function()
    if getgenv().EnableAutoPlant or getgenv().EnableAutoBreak then
        local HitboxFolder = workspace:FindFirstChild("Hitbox")
        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
        if MyHitbox then getgenv().AirPlatform.CFrame = CFrame.new(MyHitbox.Position.X, MyHitbox.Position.Y - (getgenv().GridSize / 2), MyHitbox.Position.Z) end
        if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end
    else
        getgenv().AirPlatform.CFrame = CFrame.new(0, -9999, 0)
    end
end)

-- ========================================== --
-- [[ FUNGSI JALAN PER GRID ]]
-- ========================================== --
local function WalkToGrid(tX, tY)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end

    local startZ = MyHitbox.Position.Z
    local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    while (currentX ~= tX or currentY ~= tY) do
        if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end
        if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1)
        elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end
        
        local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
        MyHitbox.CFrame = CFrame.new(newWorldPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
        task.wait(getgenv().StepDelay)
    end
end

-- ========================================== --
-- [[ LOGIKA UTAMA: AUTO PLANT & BREAK ]]
-- ========================================== --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")
local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist") 

if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        local isPlanting = getgenv().EnableAutoPlant
        local isBreaking = getgenv().EnableAutoBreak

        if isPlanting or isBreaking then
            if isPlanting and getgenv().SelectedSeed == "" then 
                warn("Pilih Seed dulu di Dropdown sebelum mulai Plant!")
                getgenv().EnableAutoPlant = false
                task.wait(1); continue 
            end

            local absStepY = math.max(1, math.abs(getgenv().FarmStepY))
            local stepY = (getgenv().FarmStartY > getgenv().FarmEndY) and -absStepY or absStepY
            local isMovingRight = true

            for y = getgenv().FarmStartY, getgenv().FarmEndY, stepY do
                if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end

                local startX = isMovingRight and getgenv().FarmStartX or getgenv().FarmEndX
                local endX = isMovingRight and getgenv().FarmEndX or getgenv().FarmStartX
                local stepX = isMovingRight and 1 or -1

                WalkToGrid(startX, y)
                task.wait(0.2) 

                for x = startX, endX, stepX do
                    if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end

                    WalkToGrid(x, y)
                    task.wait(0.1) 

                    -- INI KUNCI FIX-NYA: Diubah jadi Teks (String) seperti "36, 38"
                    local targetGridString = tostring(x) .. ", " .. tostring(y)

                    if getgenv().EnableAutoPlant then
                        local seedSlot = GetSlotByItemID(getgenv().SelectedSeed)
                        if not seedSlot then
                            warn("Seed habis bos!")
                            getgenv().EnableAutoPlant = false
                            break
                        end
                        pcall(function() RemotePlace:FireServer(targetGridString, seedSlot) end)
                        task.wait(getgenv().PlaceDelay)

                    elseif getgenv().EnableAutoBreak then
                        for i = 1, getgenv().HitsPerBlock do
                            if not getgenv().EnableAutoBreak then break end
                            pcall(function() RemoteBreak:FireServer(targetGridString) end)
                            task.wait(getgenv().BreakDelay)
                        end
                    end
                end
                isMovingRight = not isMovingRight
            end
            
            if getgenv().EnableAutoPlant or getgenv().EnableAutoBreak then
                print("Selesai mengeksekusi seluruh area!")
                getgenv().EnableAutoPlant = false
                getgenv().EnableAutoBreak = false
            end
        end
        task.wait(1)
    end
end)CreateTextBox(TargetPage, "Keyword Panen (opsional)", getgenv().ReadyKeyword, "ReadyKeyword")

CreateToggle(TargetPage, "🚜 START AUTO PLANT", "EnableAutoPlant", false)
CreateToggle(TargetPage, "🔨 START AUTO HARVEST", "EnableAutoBreak", true)

-- ========================================== --
-- [[ SISTEM FULL MODFLY (INVISIBLE PLATFORM) ]]
-- ========================================== --
if getgenv().KzoyzModFlyHeartbeat then getgenv().KzoyzModFlyHeartbeat:Disconnect(); getgenv().KzoyzModFlyHeartbeat = nil end
if workspace:FindFirstChild("KzoyzAirWalk") then workspace.KzoyzAirWalk:Destroy() end

local AirPlat = Instance.new("Part")
AirPlat.Name = "KzoyzAirWalk"
AirPlat.Size = Vector3.new(getgenv().GridSize + 1, 1, getgenv().GridSize + 1)
AirPlat.Anchored = true; AirPlat.CanCollide = true; AirPlat.Transparency = 1 
AirPlat.Parent = workspace
getgenv().AirPlatform = AirPlat

getgenv().KzoyzModFlyHeartbeat = RunService.Heartbeat:Connect(function()
    if getgenv().EnableAutoPlant or getgenv().EnableAutoBreak then
        local HitboxFolder = workspace:FindFirstChild("Hitbox")
        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
        
        if MyHitbox then 
            getgenv().AirPlatform.CFrame = CFrame.new(MyHitbox.Position.X, MyHitbox.Position.Y - (getgenv().GridSize / 2), MyHitbox.Position.Z)
        end
        if PlayerMovement then
            pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end)
        end
    else
        getgenv().AirPlatform.CFrame = CFrame.new(0, -9999, 0)
    end
end)

-- ========================================== --
-- [[ SISTEM SCANNER (MATA VIRTUAL) ]]
-- ========================================== --
local function IsReadyToHarvest(obj)
    local name = string.lower(obj.Name)
    local keyword = string.lower(tostring(getgenv().ReadyKeyword))
    
    -- Cek via Keyword Name
    if keyword ~= "" and string.find(name, keyword) then return true end
    if string.find(name, "ready") then return true end
    
    -- Cek via Attributes (Bawaan Game)
    for attr, val in pairs(obj:GetAttributes()) do
        local lowerAttr = string.lower(attr)
        if (lowerAttr == "ready" and val == true) or (lowerAttr == "growth" and (val == 100 or val == 1)) then 
            return true 
        end
    end
    return false
end

local function ScanGrid(X, Y)
    local zPos = 0
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)
    if MyHitbox then zPos = MyHitbox.Position.Z end
    
    local pos = Vector3.new(X * getgenv().GridSize, Y * getgenv().GridSize, zPos)
    local hitBoxSize = Vector3.new(1.5, 1.5, 1.5) -- Scan kotak kecil di tengah grid aja biar ga salah baca tetangga
    
    local params = OverlapParams.new()
    local targetFolders = {}
    if workspace:FindFirstChild("Tiles") then table.insert(targetFolders, workspace.Tiles) end
    if workspace:FindFirstChild("Backgrounds") then table.insert(targetFolders, workspace.Backgrounds) end
    
    if #targetFolders > 0 then
        params.FilterDescendantsInstances = targetFolders
        params.FilterType = Enum.RaycastFilterType.Include
    else
        -- Kalo folder gak standard, filter karakter doang
        params.FilterDescendantsInstances = {LP.Character, workspace:FindFirstChild("Hitbox")}
        params.FilterType = Enum.RaycastFilterType.Exclude
    end
    
    local partsInGrid = workspace:GetPartBoundsInBox(CFrame.new(pos), hitBoxSize, params)
    
    local isOccupied = false
    local isReady = false
    
    if #partsInGrid > 0 then
        isOccupied = true
        for _, p in ipairs(partsInGrid) do
            local obj = p:FindFirstAncestorWhichIsA("Model") or p
            if IsReadyToHarvest(obj) then
                isReady = true
                break
            end
        end
    end
    
    return isOccupied, isReady
end

-- ========================================== --
-- [[ FUNGSI JALAN PER GRID ]]
-- ========================================== --
local function WalkToGrid(tX, tY)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end

    local startZ = MyHitbox.Position.Z
    local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    while (currentX ~= tX or currentY ~= tY) do
        if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end
        
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

-- ========================================== --
-- [[ LOGIKA UTAMA: AUTO PLANT & BREAK ]]
-- ========================================== --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")
local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist") 

if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        local isPlanting = getgenv().EnableAutoPlant
        local isBreaking = getgenv().EnableAutoBreak

        if isPlanting or isBreaking then
            if isPlanting and getgenv().SelectedSeed == "" then 
                warn("Pilih Seed dulu di Dropdown sebelum mulai Plant!")
                getgenv().EnableAutoPlant = false
                task.wait(1); continue 
            end

            local absStepY = math.max(1, math.abs(getgenv().FarmStepY))
            local stepY = (getgenv().FarmStartY > getgenv().FarmEndY) and -absStepY or absStepY
            local isMovingRight = true

            for y = getgenv().FarmStartY, getgenv().FarmEndY, stepY do
                if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end

                local startX = isMovingRight and getgenv().FarmStartX or getgenv().FarmEndX
                local endX = isMovingRight and getgenv().FarmEndX or getgenv().FarmStartX
                local stepX = isMovingRight and 1 or -1

                WalkToGrid(startX, y)
                task.wait(0.2) 

                for x = startX, endX, stepX do
                    if not (getgenv().EnableAutoPlant or getgenv().EnableAutoBreak) then break end

                    WalkToGrid(x, y)
                    task.wait(0.1) 

                    local targetGrid = Vector2.new(x, y)
                    
                    -- SCANNER VIRTUAL DI KOORDINAT SAAT INI
                    local isOccupied, isReady = ScanGrid(x, y)

                    if getgenv().EnableAutoPlant then
                        -- Cuma tanam kalo kotak bener-bener KOSONG
                        if not isOccupied then
                            local seedSlot = GetSlotByItemID(getgenv().SelectedSeed)
                            if not seedSlot then
                                warn("Seed habis bos!")
                                getgenv().EnableAutoPlant = false
                                break
                            end
                            pcall(function() RemotePlace:FireServer(targetGrid, seedSlot) end)
                            task.wait(getgenv().PlaceDelay)
                        end

                    elseif getgenv().EnableAutoBreak then
                        -- Cuma pukul kalo ada benda DAN berstatus READY (Pohon mateng)
                        if isOccupied and isReady then
                            for i = 1, getgenv().HitsPerBlock do
                                if not getgenv().EnableAutoBreak then break end
                                pcall(function() RemoteBreak:FireServer(targetGrid) end)
                                task.wait(getgenv().BreakDelay)
                            end
                        end
                    end
                end
                
                isMovingRight = not isMovingRight
            end
            
            if getgenv().EnableAutoPlant or getgenv().EnableAutoBreak then
                print("Selesai mengeksekusi seluruh area!")
                getgenv().EnableAutoPlant = false
                getgenv().EnableAutoBreak = false
            end
        end
        task.wait(1)
    end
end)
