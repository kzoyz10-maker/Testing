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

getgenv().ScriptVersion = "Auto Plant Full World v1.0" 

-- ========================================== --
-- [[ SETTING KECEPATAN BASE ]]
getgenv().PlaceDelay = 0.05  
getgenv().StepDelay = 0.1   
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser") 
local RunService = game:GetService("RunService")

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

if getgenv().KzoyzPlantLoop then task.cancel(getgenv().KzoyzPlantLoop); getgenv().KzoyzPlantLoop = nil end

-- [[ VARIABEL GLOBAL ]] --
getgenv().GridSize = 4.5
getgenv().EnableFullPlant = false
getgenv().PlantSeedID = ""
getgenv().WorldMinX = 0
getgenv().WorldMaxX = 50
getgenv().WorldMinY = 0
getgenv().WorldMaxY = 10

-- Modul Game Internal --
local InventoryMod
pcall(function() InventoryMod = require(RS:WaitForChild("Modules"):WaitForChild("Inventory")) end)

local function GetSlotByItemID(targetID)
    if not InventoryMod or not InventoryMod.Stacks then return nil end
    for slotIndex, data in pairs(InventoryMod.Stacks) do
        if type(data) == "table" and data.Id and tostring(data.Id) == tostring(targetID) then
            if not data.Amount or data.Amount > 0 then return slotIndex end
        end
    end
    return nil
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

local function WalkToGrid(tX, tY)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end

    local startZ = MyHitbox.Position.Z
    local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    while (currentX ~= tX or currentY ~= tY) do
        if not getgenv().EnableFullPlant then break end
        if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1)
        elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end
        
        local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
        MyHitbox.CFrame = CFrame.new(newWorldPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
        task.wait(getgenv().StepDelay)
    end
end

-- [[ UI SETUP ]] --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }

function CreateToggle(Parent, Text, Var) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = ""; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); local T = Instance.new("TextLabel", Btn); T.Text = Text; T.TextColor3 = Theme.Text; T.Font = Enum.Font.GothamSemibold; T.TextSize = 12; T.Size = UDim2.new(1, -40, 1, 0); T.Position = UDim2.new(0, 10, 0, 0); T.BackgroundTransparency = 1; T.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local IC = Instance.new("UICorner", IndBg); IC.CornerRadius = UDim.new(1,0); local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); local DC = Instance.new("UICorner", Dot); DC.CornerRadius = UDim.new(1,0); IndBg.BackgroundColor3 = getgenv()[Var] and Theme.Purple or Color3.fromRGB(30,30,30); Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local Label = Instance.new("TextLabel", Frame); Label.Text = Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); local IC = Instance.new("UICorner", InputBox); IC.CornerRadius = UDim.new(0, 4); InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; local C = Instance.new("UICorner", Btn); C.CornerRadius = UDim.new(0, 6); Btn.MouseButton1Click:Connect(Callback) end
function CreateDropdown(Parent, Text, DefaultOptions, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); Frame.ClipsDescendants = true; local C = Instance.new("UICorner", Frame); C.CornerRadius = UDim.new(0, 6); local TopBtn = Instance.new("TextButton", Frame); TopBtn.Size = UDim2.new(1, 0, 0, 35); TopBtn.BackgroundTransparency = 1; TopBtn.Text = ""; local Label = Instance.new("TextLabel", TopBtn); Label.Text = Text .. ": Not Selected"; Label.TextColor3 = Theme.Text; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 11; Label.Size = UDim2.new(1, -20, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; local Icon = Instance.new("TextLabel", TopBtn); Icon.Text = "v"; Icon.TextColor3 = Theme.Purple; Icon.Font = Enum.Font.GothamBold; Icon.TextSize = 12; Icon.Size = UDim2.new(0, 20, 1, 0); Icon.Position = UDim2.new(1, -25, 0, 0); Icon.BackgroundTransparency = 1; local Scroll = Instance.new("ScrollingFrame", Frame); Scroll.Position = UDim2.new(0,0,0,35); Scroll.Size = UDim2.new(1,0,1,-35); Scroll.BackgroundTransparency = 1; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 2; Scroll.ScrollBarImageColor3 = Theme.Purple; local List = Instance.new("UIListLayout", Scroll); local isOpen = false; TopBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; if isOpen then Frame:TweenSize(UDim2.new(1, -10, 0, 110), "Out", "Quad", 0.2, true); Icon.Text = "^" else Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end end); local function RefreshOptions(Options) for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end; for _, opt in ipairs(Options) do local OptBtn = Instance.new("TextButton", Scroll); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); OptBtn.TextColor3 = Theme.Text; OptBtn.Text = tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 11; OptBtn.MouseButton1Click:Connect(function() getgenv()[Var] = opt; Label.Text = Text .. ": " .. tostring(opt); isOpen = false; Frame:TweenSize(UDim2.new(1, -10, 0, 35), "Out", "Quad", 0.2, true); Icon.Text = "v" end) end; Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 25) end; RefreshOptions(DefaultOptions); return RefreshOptions end

-- [[ INJECT MENU ]] --
local RefreshSeedDropdown = CreateDropdown(TargetPage, "Pilih Seed", ScanAvailableItems(), "PlantSeedID")
CreateButton(TargetPage, "🔄 Refresh Tas", function() local newItems = ScanAvailableItems(); RefreshSeedDropdown(newItems) end)

CreateToggle(TargetPage, "🚀 START AUTO PLANT", "EnableFullPlant")

-- AUTO-UPDATE POSISI DI UI
local MinXBox = CreateTextBox(TargetPage, "Start X (Kiri)", getgenv().WorldMinX, "WorldMinX")
local MinYBox = CreateTextBox(TargetPage, "Start Y (Bawah)", getgenv().WorldMinY, "WorldMinY")
CreateButton(TargetPage, "📍 Set Titik Awal (Di Sini)", function() 
    local H = workspace.Hitbox:FindFirstChild(LP.Name) 
    if H then 
        local bx = math.floor(H.Position.X/4.5+0.5)
        local by = math.floor(H.Position.Y/4.5+0.5)
        getgenv().WorldMinX = bx; getgenv().WorldMinY = by
        MinXBox.Text = tostring(bx); MinYBox.Text = tostring(by)
    end 
end)

local MaxXBox = CreateTextBox(TargetPage, "End X (Kanan)", getgenv().WorldMaxX, "WorldMaxX")
local MaxYBox = CreateTextBox(TargetPage, "End Y (Atas)", getgenv().WorldMaxY, "WorldMaxY")
CreateButton(TargetPage, "📍 Set Titik Akhir (Di Sini)", function() 
    local H = workspace.Hitbox:FindFirstChild(LP.Name) 
    if H then 
        local bx = math.floor(H.Position.X/4.5+0.5)
        local by = math.floor(H.Position.Y/4.5+0.5)
        getgenv().WorldMaxX = bx; getgenv().WorldMaxY = by
        MaxXBox.Text = tostring(bx); MaxYBox.Text = tostring(by)
    end 
end)

-- [[ LOGIC AUTO PLANT (ZIG-ZAG) ]] --
local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")

getgenv().KzoyzPlantLoop = task.spawn(function()
    while true do
        if getgenv().EnableFullPlant then
            if getgenv().PlantSeedID == "" then
                -- Tunggu sebentar kalau Seed belum dipilih
                task.wait(2)
                continue
            end
            
            -- Normalisasi titik X dan Y (biar ga pusing kebolak-balik)
            local minX = math.min(getgenv().WorldMinX, getgenv().WorldMaxX)
            local maxX = math.max(getgenv().WorldMinX, getgenv().WorldMaxX)
            local minY = math.min(getgenv().WorldMinY, getgenv().WorldMaxY)
            local maxY = math.max(getgenv().WorldMinY, getgenv().WorldMaxY)

            -- Looping per baris (dari bawah ke atas)
            for y = minY, maxY do
                if not getgenv().EnableFullPlant then break end
                
                -- [[ LOGIKA ZIG-ZAG ]]
                -- Baris genap dari Kiri -> Kanan, Ganjil dari Kanan -> Kiri
                local isEvenRow = (y % 2 == 0)
                local startX = isEvenRow and minX or maxX
                local endX = isEvenRow and maxX or minX
                local step = isEvenRow and 1 or -1
                
                -- Karakter jalan dulu ke ujung baris biar ga miring
                WalkToGrid(startX, y)
                task.wait(0.2)
                
                for x = startX, endX, step do
                    if not getgenv().EnableFullPlant then break end
                    
                    local seedSlot = GetSlotByItemID(getgenv().PlantSeedID)
                    if not seedSlot then 
                        -- Toggle langsung mati kalau seed habis di tas
                        getgenv().EnableFullPlant = false
                        break 
                    end
                    
                    WalkToGrid(x, y)
                    task.wait(0.05) -- Jeda kecil biar hitbox lurus
                    
                    RemotePlace:FireServer(Vector2.new(x, y), seedSlot)
                    task.wait(getgenv().PlaceDelay)
                end
            end
            
            if getgenv().EnableFullPlant then
                -- Kalau udah berhasil tembus sampai atas, otomatis mati
                getgenv().EnableFullPlant = false
            end
        end
        task.wait(1)
    end
end)
