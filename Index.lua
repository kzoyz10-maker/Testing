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

getgenv().ScriptVersion = "Auto Plant v5.0 - True GT Style" 

-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkDelay = 0.25 -- Jeda gerak per-kotak (Anti-Glitch Server)
getgenv().PlaceDelay = 0.1  -- Jeda setelah nanam
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

if getgenv().KzoyzPlantLoop then task.cancel(getgenv().KzoyzPlantLoop); getgenv().KzoyzPlantLoop = nil end
if getgenv().KzoyzModFlyLoop then getgenv().KzoyzModFlyLoop:Disconnect(); getgenv().KzoyzModFlyLoop = nil end
if workspace:FindFirstChild("KzoyzAirWalk") then workspace.KzoyzAirWalk:Destroy() end

getgenv().ModFly = false
getgenv().EnableGTPlant = false
getgenv().PlantSeedID = ""

-- [[ SISTEM MOD FLY PLATFORM ]] --
local AirPlat = Instance.new("Part")
AirPlat.Name = "KzoyzAirWalk"
AirPlat.Size = Vector3.new(getgenv().GridSize + 1, 1, getgenv().GridSize + 1)
AirPlat.Anchored = true; AirPlat.CanCollide = true; AirPlat.Transparency = 1 
AirPlat.Parent = workspace
getgenv().AirPlatform = AirPlat

getgenv().KzoyzModFlyLoop = RunService.Stepped:Connect(function()
    if getgenv().ModFly then
        local H = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)
        if H then getgenv().AirPlatform.CFrame = CFrame.new(H.Position.X, H.Position.Y - (getgenv().GridSize / 2), H.Position.Z) end
        if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end
    else
        getgenv().AirPlatform.CFrame = CFrame.new(0, -9999, 0)
    end
end)

-- [[ FUNGSI TAS & MAP ]] --
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

-- MEMBACA SELURUH MAP (Support BasePart & Model)
local function GetWorldMap()
    local map = {}
    for x = -10, 110 do map[x] = {} end -- Beri buffer ukuran map
    
    local tilesFolder = workspace:FindFirstChild("Tiles")
    if tilesFolder then
        for _, block in ipairs(tilesFolder:GetChildren()) do
            local pos = nil
            if block:IsA("BasePart") then pos = block.Position
            elseif block:IsA("Model") and block.PrimaryPart then pos = block.PrimaryPart.Position
            elseif block:IsA("Model") then
                local firstPart = block:FindFirstChildWhichIsA("BasePart")
                if firstPart then pos = firstPart.Position end
            end
            
            if pos then
                local gX = math.floor(pos.X / getgenv().GridSize + 0.5)
                local gY = math.floor(pos.Y / getgenv().GridSize + 0.5)
                if map[gX] then map[gX][gY] = true end
            end
        end
    end 
    return map
end

-- PENCARI JALAN PINTAR (Step-by-step Anti Glitch)
local function SmartWalkTo(tX, tY, map)
    local H = workspace.Hitbox:FindFirstChild(LP.Name)
    if not H then return end
    local startZ = H.Position.Z
    
    while getgenv().EnableGTPlant do
        local cX = math.floor(H.Position.X / getgenv().GridSize + 0.5)
        local cY = math.floor(H.Position.Y / getgenv().GridSize + 0.5)
        
        if cX == tX and cY == tY then break end -- Sampai Tujuan
        
        local nextX = cX
        local nextY = cY
        
        if cY < tY then -- Butuh Naik
            if map[cX] and map[cX][cY+1] then
                -- Atap ketutup! Geser cari celah.
                local dir = (tX > cX) and 1 or -1
                if cX == tX then dir = 1 end
                nextX = cX + dir
                getgenv().ModFly = false
            else
                -- Atap kebuka, terbang naik
                nextY = cY + 1
                getgenv().ModFly = true
            end
        elseif cY > tY then -- Butuh Turun
            nextY = cY - 1
            getgenv().ModFly = false
        else -- Sejajar, jalan horizontal
            nextX = cX + ((tX > cX) and 1 or -1)
            getgenv().ModFly = false
        end
        
        local newPos = Vector3.new(nextX * getgenv().GridSize, nextY * getgenv().GridSize, startZ)
        H.CFrame = CFrame.new(newPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newPos end) end
        task.wait(getgenv().WalkDelay) -- Tunggu server register jalan
    end
end

-- [[ UI SETUP ]] --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }
function CreateToggle(Parent, Text, Var) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner", IndBg); IC.CornerRadius = UDim.new(1,0); local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner", Dot); DC.CornerRadius = UDim.new(1,0); IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30); Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local Label = Instance.new("TextLabel", Frame); Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); local IC = Instance.new("UICorner", InputBox); IC.CornerRadius = UDim.new(0, 4); InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end
function CreateDropdown(Parent, Text, DefaultOptions, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""; local Label = Instance.new("TextLabel", TopBtn); Label.Text = Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; local Icon = Instance.new("TextLabel", TopBtn); Icon.Text = "v"; Icon.TextColor3 = Theme.Purple; Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 12; Icon.Size = UDim2.new(0, 20, 1, 0); Icon.Position = UDim2.new(1, -25, 0, 0); Icon.BackgroundTransparency = 1; local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Theme.Purple; local List = Instance.new("UIListLayout", Scroll); local isOpen = false; TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true); Icon.Text = "^" else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end end); local function RefreshOptions(Options) for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end; for _, opt in ipairs(Options) do local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11; OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) end; RefreshOptions(DefaultOptions); return RefreshOptions end

-- INJECT --
local RefreshSeedDropdown = CreateDropdown(TargetPage, "Pilih Seed", ScanAvailableItems(), "PlantSeedID")
CreateButton(TargetPage, "🔄 Refresh Tas", function() RefreshSeedDropdown(ScanAvailableItems()) end)

CreateTextBox(TargetPage, "Speed Jalan (Delay)", getgenv().WalkDelay, "WalkDelay")
CreateTextBox(TargetPage, "SuuuNanam (Delay)", getgenv().PlaceDelay, "PlaceDelay")

CreateToggle(TargetPage, "🚜 START GT AUTO PLANT", "EnableGTPlant")

-- [[ LOGIC AUTO PLANT GT STYLE ]] --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")

getgenv().KzoyzPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableGTPlant then
            local seedSlot = GetSlotByItemID(getgenv().PlantSeedID)
            if not seedSlot then 
                warn("Seed kosong / tidak valid!")
                getgenv().EnableGTPlant = false; getgenv().ModFly = false
                task.wait(2); continue 
            end
            
            local H = workspace.Hitbox:FindFirstChild(LP.Name)
            if not H then task.wait(1); continue end
            
            local myY = math.floor(H.Position.Y / getgenv().GridSize + 0.5)
            local map = GetWorldMap()
            
            -- 1. Kumpulin semua list titik tanah yang kosong
            local targetList = {}
            local isLeftToRight = true -- Pola Zig-Zag Awal
            
            for y = myY, 60 do -- Mulai dari posisi player sampai batas atas map
                local rowTargets = {}
                local rowHasDirt = false
                
                for x = 0, 99 do
                    -- Syarat ditanam: Grid saat ini kosong & Bawahnya ada block
                    local isAir = not (map[x] and map[x][y])
                    local hasDirt = (map[x] and map[x][y-1])
                    
                    if isAir and hasDirt then
                        table.insert(rowTargets, {x = x, y = y})
                        rowHasDirt = true
                    end
                end
                
                -- 2. Sortir ZigZag biar jalannya kayak uler (rapi)
                if rowHasDirt then
                    table.sort(rowTargets, function(a, b)
                        if isLeftToRight then return a.x < b.x else return a.x > b.x end
                    end)
                    
                    for _, t in ipairs(rowTargets) do
                        table.insert(targetList, t)
                    end
                    isLeftToRight = not isLeftToRight -- Putar balik untuk baris atasnya
                end
            end
            
            -- 3. EKSEKUSI TANAM SATU PERSATU DENGAN SMART WALK
            if #targetList > 0 then
                for _, target in ipairs(targetList) do
                    if not getgenv().EnableGTPlant then break end
                    
                    -- Cek seed sebelum tanam
                    seedSlot = GetSlotByItemID(getgenv().PlantSeedID)
                    if not seedSlot then getgenv().EnableGTPlant = false; break end
                    
                    -- Jalan pelan-pelan & otomatis pakai fly kalau butuh manjat
                    SmartWalkTo(target.x, target.y, map)
                    
                    if getgenv().EnableGTPlant then
                        RemotePlace:FireServer(Vector2.new(target.x, target.y), seedSlot)
                        task.wait(getgenv().PlaceDelay)
                    end
                end
            end
            
            -- Matikan kalau list target udah habis / beres 1 map
            getgenv().EnableGTPlant = false
            getgenv().ModFly = false
        end
        task.wait(1)
    end
end)
