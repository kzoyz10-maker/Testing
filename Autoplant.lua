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

getgenv().ScriptVersion = "Auto Plant v2.0 - Auto Detect & Smart Path" 

-- ========================================== --
getgenv().PlaceDelay = 0.05  
getgenv().StepDelay = 0.1   
getgenv().GridSize = 4.5
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
getgenv().EnableSmartPlant = false
getgenv().PlantSeedID = ""
getgenv().ScanRadiusX = 50 -- Jarak bot nyari ladang ke kiri-kanan
getgenv().ScanRadiusY = 10 -- Jarak bot nyari ladang ke atas-bawah

-- [[ SISTEM MOD FLY (DINAMIS) ]] --
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

-- Modul Tas
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
    if #items == 0 then items = {"Kosong"} end
    return items
end

-- [[ SISTEM SENSOR RAYCAST ]] --
-- Mengecek apakah ada benda padat di arah tertentu
local function CheckSolidBlock(startX, startY, dirX, dirY)
    local H = workspace.Hitbox:FindFirstChild(LP.Name)
    if not H then return false end
    
    local origin = Vector3.new(startX * getgenv().GridSize, startY * getgenv().GridSize, H.Position.Z)
    local direction = Vector3.new(dirX * getgenv().GridSize, dirY * getgenv().GridSize, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace:FindFirstChild("Hitbox"), getgenv().AirPlatform}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result ~= nil -- Return True kalau nabrak block
end

-- [[ SMART MOVEMENT ]] --
local function MoveToWithEdgeDetection(tX, tY)
    local H = workspace.Hitbox:FindFirstChild(LP.Name)
    if not H then return end
    local startZ = H.Position.Z

    while true do
        if not getgenv().EnableSmartPlant then break end
        
        local cX = math.floor(H.Position.X / getgenv().GridSize + 0.5)
        local cY = math.floor(H.Position.Y / getgenv().GridSize + 0.5)
        
        if cX == tX and cY == tY then break end -- Udah sampai

        -- JIKA HARUS NAIK KE ATAS (Mod Fly)
        if tY > cY then
            -- Cek Atap, mentok gak?
            local isCeilingBlocked = CheckSolidBlock(cX, cY, 0, 1)
            
            if isCeilingBlocked then
                -- Atap mentok! Jalan ke ujung platform dulu.
                getgenv().ModFly = false -- Jalan di tanah biasa
                local testX = cX
                local foundGap = false
                
                -- Cari celah ke arah tujuan X
                local searchDir = (tX > cX) and 1 or -1
                for i = 1, 30 do -- Coba scan sampai 30 blok ke depan
                    testX = testX + searchDir
                    if not CheckSolidBlock(testX, cY, 0, 1) then -- Atapnya bolong!
                        foundGap = true
                        break
                    end
                end
                
                -- Kalau ketemu celahnya, jalan ke situ
                if foundGap then
                    cX = cX + (testX > cX and 1 or -1)
                else
                    -- Mentok semua? Coba jalan paksa aja
                    cX = cX + searchDir
                end
            else
                -- Atap bolong, aman buat terbang naik!
                getgenv().ModFly = true
                cY = cY + 1
            end
            
        -- JIKA HARUS TURUN KE BAWAH
        elseif tY < cY then
            getgenv().ModFly = false -- Matiin Fly biar jatuh
            cY = cY - 1
            
        -- JIKA CUMA JALAN LURUS KIRI/KANAN
        else
            getgenv().ModFly = false 
            cX = cX + (tX > cX and 1 or -1)
        end

        local newPos = Vector3.new(cX * getgenv().GridSize, cY * getgenv().GridSize, startZ)
        H.CFrame = CFrame.new(newPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newPos end) end
        task.wait(getgenv().StepDelay)
    end
end

-- [[ UI SETUP ]] --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }
function CreateToggle(Parent, Text, Var) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner", IndBg); IC.CornerRadius = UDim.new(1,0); local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner", Dot); DC.CornerRadius = UDim.new(1,0); IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30); Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) end
function CreateDropdown(Parent, Text, DefaultOptions, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""; local Label = Instance.new("TextLabel", TopBtn); Label.Text = Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; local Icon = Instance.new("TextLabel", TopBtn); Icon.Text = "v"; Icon.TextColor3 = Theme.Purple; Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 12; Icon.Size = UDim2.new(0, 20, 1, 0); Icon.Position = UDim2.new(1, -25, 0, 0); Icon.BackgroundTransparency = 1; local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Theme.Purple; local List = Instance.new("UIListLayout", Scroll); local isOpen = false; TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true); Icon.Text = "^" else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end end); local function RefreshOptions(Options) for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end; for _, opt in ipairs(Options) do local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11; OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) end; RefreshOptions(DefaultOptions); return RefreshOptions end

-- [[ INJECT MENU ]] --
local RefreshSeedDropdown = CreateDropdown(TargetPage, "Pilih Seed", ScanAvailableItems(), "PlantSeedID")
CreateButton(TargetPage, "🔄 Refresh Tas", function() RefreshSeedDropdown(ScanAvailableItems()) end)

CreateToggle(TargetPage, "🤖 START SMART AUTO PLANT", "EnableSmartPlant")

-- [[ LOGIC AUTO PLANT SMART SENSOR ]] --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")

getgenv().KzoyzPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartPlant then
            local seedSlot = GetSlotByItemID(getgenv().PlantSeedID)
            if not seedSlot then 
                getgenv().EnableSmartPlant = false
                getgenv().ModFly = false
                task.wait(1)
                continue
            end
            
            local H = workspace.Hitbox:FindFirstChild(LP.Name)
            if H then
                local myX = math.floor(H.Position.X / getgenv().GridSize + 0.5)
                local myY = math.floor(H.Position.Y / getgenv().GridSize + 0.5)
                
                local foundTarget = false
                
                -- SENSOR SCAN: Nyari area kosong di sekitar player
                -- Dia bakal scan dari bawah ke atas, kiri ke kanan
                for scanY = myY - getgenv().ScanRadiusY, myY + getgenv().ScanRadiusY do
                    if not getgenv().EnableSmartPlant then break end
                    
                    for scanX = myX - getgenv().ScanRadiusX, myX + getgenv().ScanRadiusX do
                        -- Cek 1: Apakah di grid Bawah (Y-1) ada tanah?
                        local hasDirtBelow = CheckSolidBlock(scanX, scanY, 0, -1)
                        -- Cek 2: Apakah grid ini (Y) KOSONG (gak ada tanaman)?
                        local isGridEmpty = not CheckSolidBlock(scanX, scanY, 0, 0)
                        
                        if hasDirtBelow and isGridEmpty then
                            -- Wah ada ladang kosong nih! Samperin!
                            MoveToWithEdgeDetection(scanX, scanY)
                            task.wait(0.05)
                            RemotePlace:FireServer(Vector2.new(scanX, scanY), seedSlot)
                            task.wait(getgenv().PlaceDelay)
                            
                            foundTarget = true
                            break -- Balik scan dari awal biar gerakannya teratur
                        end
                    end
                    if foundTarget then break end
                end
                
                if not foundTarget then
                    -- Kalau muter-muter 100 block gak nemu tanah kosong, matiin diri.
                    getgenv().EnableSmartPlant = false
                    getgenv().ModFly = false
                end
            end
        end
        task.wait(0.5)
    end
end)
