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

getgenv().ScriptVersion = "Auto Plant v4.0 - GT Style (Anti Glitch)" 

-- ========================================== --
getgenv().GridSize = 4.5
-- BISA DIATUR DARI MENU SEKARANG:
getgenv().WalkDelay = 0.25 -- Jeda saat pindah 1 block (Makin gede makin pelan/aman)
getgenv().PlaceDelay = 0.1 -- Jeda setelah naruh seed
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

local function GetWorldMap()
    local map = {}
    for x = 0, 99 do map[x] = {} end 
    local tilesFolder = workspace:FindFirstChild("Tiles")
    if tilesFolder then
        for _, block in ipairs(tilesFolder:GetChildren()) do
            if block:IsA("BasePart") then
                local gX = math.floor(block.Position.X / getgenv().GridSize + 0.5)
                local gY = math.floor(block.Position.Y / getgenv().GridSize + 0.5)
                if gX >= 0 and gX <= 99 and gY >= 0 and gY <= 59 then map[gX][gY] = true end
            end
        end
    end return map
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
CreateTextBox(TargetPage, "Speed Nanam (Delay)", getgenv().PlaceDelay, "PlaceDelay")

CreateToggle(TargetPage, "🚜 START GT AUTO PLANT", "EnableGTPlant")

-- [[ LOGIC AUTO PLANT GT STYLE ]] --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")

getgenv().KzoyzPlantLoop = task.spawn(function()
    local isFirstRow = true
    local direction = 1 -- 1 = Ke Kanan, -1 = Ke Kiri
    
    -- Fungsi Anti-Glitch (Gerak 1 block, pause)
    local function StepTo(tX, tY, startZ)
        if not getgenv().EnableGTPlant then return false end
        local H = workspace.Hitbox:FindFirstChild(LP.Name)
        if H then
            local newPos = Vector3.new(tX * getgenv().GridSize, tY * getgenv().GridSize, startZ)
            H.CFrame = CFrame.new(newPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = newPos end) end
        end
        task.wait(getgenv().WalkDelay) -- PELAN-PELAN BIAR SERVER GAK MARAH
        return true
    end

    while getgenv().EnableGTPlant do
        local seedSlot = GetSlotByItemID(getgenv().PlantSeedID)
        if not seedSlot then getgenv().EnableGTPlant = false; getgenv().ModFly = false; break end

        local H = workspace.Hitbox:FindFirstChild(LP.Name)
        if not H then task.wait(0.5) continue end
        
        local startZ = H.Position.Z
        local cX = math.floor(H.Position.X / getgenv().GridSize + 0.5)
        local cY = math.floor(H.Position.Y / getgenv().GridSize + 0.5)
        
        local Map = GetWorldMap()

        -- AWAL MULAI: Harus maksain jalan ke UJUNG KIRI dulu
        if isFirstRow then
            direction = 1
            while cX > 0 and getgenv().EnableGTPlant do
                if Map[cX-1] and Map[cX-1][cY] then break end -- Kalo nabrak tembok kiri, stop
                cX = cX - 1
                StepTo(cX, cY, startZ)
            end
            isFirstRow = false
            task.wait(0.5)
        end

        -- FASE TANAM (Jalan sebaris)
        while getgenv().EnableGTPlant do
            -- 1. Cek kalau bisa nanam di pijakan ini
            local hasDirt = Map[cX] and Map[cX][cY-1]
            local isEmpty = Map[cX] and not Map[cX][cY]
            
            if hasDirt and isEmpty then
                RemotePlace:FireServer(Vector2.new(cX, cY), seedSlot)
                Map[cX][cY] = true -- Tandai lokal biar gak double
                task.wait(getgenv().PlaceDelay)
            end
            
            -- 2. Cek apakah bisa maju ke kotak depannya
            local nX = cX + direction
            local isNextWall = Map[nX] and Map[nX][cY]
            local isNextEdge = (nX < 0) or (nX > 99)
            local isNextHole = Map[nX] and not Map[nX][cY-1] -- Gak ada tanah di depan
            
            if isNextWall or isNextEdge or isNextHole then
                -- MENTOK! Waktunya cari jalan naik
                break
            else
                -- BISA MAJU, langkahkan kaki 1 grid
                cX = nX
                StepTo(cX, cY, startZ)
            end
        end

        if not getgenv().EnableGTPlant then break end

        -- FASE CARI ATAP BOLONG BUAT NAIK
        local holeX = cX
        local foundHole = false
        local searchDir = -direction -- Cari lobang ke arah kebalikan

        while holeX >= 0 and holeX <= 99 do
            -- Cek kalau di atas kepala kosong
            if not (Map[holeX] and Map[holeX][cY+1]) and not (Map[holeX] and Map[holeX][cY+2]) then
                foundHole = true
                break
            end
            holeX = holeX + searchDir
        end

        if foundHole then
            -- 1. Jalan ke posisi lobang
            while cX ~= holeX and getgenv().EnableGTPlant do
                cX = cX + (holeX > cX and 1 or -1)
                StepTo(cX, cY, startZ)
            end
            
            -- 2. Terbang ke atas ngelewatin lobang
            getgenv().ModFly = true
            task.wait(0.3)
            
            while getgenv().EnableGTPlant do
                cY = cY + 1
                StepTo(cX, cY, startZ)
                
                -- Sambil naik, liat ke samping, ada ladang baru gak?
                local checkSideX = cX + (-direction)
                if Map[checkSideX] and Map[checkSideX][cY-1] then
                    -- Nemu lantai ladang baru!
                    break
                end
                
                if cY > 59 then getgenv().EnableGTPlant = false; break end -- Kalo bablas ke langit, matiin
            end
            
            -- 3. Udah sampai lantai baru, matiin fly, pindah 1 blok ke ladang, balik arah
            getgenv().ModFly = false
            direction = -direction 
            task.wait(0.3)
            
            cX = cX + direction
            StepTo(cX, cY, startZ)
        else
            -- Kalau gada lobang sama sekali buat naik, berarti ladang udah full
            getgenv().EnableGTPlant = false
        end
    end
end)
