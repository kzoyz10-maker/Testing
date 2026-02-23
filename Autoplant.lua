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

getgenv().ScriptVersion = "Auto Plant Full World - Scan & Plant"

-- ========================================== --
getgenv().GridSize = 4.5
getgenv().EnableAutoPlant = false
getgenv().FarmStartX = 0
getgenv().FarmEndX = 50
getgenv().FarmBottomY = 10 -- Batas bawah mentok farming
getgenv().SelectedSeed = ""
-- ========================================== --

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Fungsi tas (Bawaanmu)
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

-- UI Setup (Bawaanmu - Disingkat biar rapi)
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Purple = Color3.fromRGB(140, 80, 255) }
function CreateToggle(Parent, Text, Var) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = "  " .. Text; Btn.TextColor3 = Theme.Text; Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 12; Btn.TextXAlignment = Enum.TextXAlignment.Left; local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 36, 0, 18); IndBg.Position = UDim2.new(1, -45, 0.5, -9); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = getgenv()[Var] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); Btn.MouseButton1Click:Connect(function() getgenv()[Var] = not getgenv()[Var]; if getgenv()[Var] then Dot:TweenPosition(UDim2.new(1, -16, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Purple else Dot:TweenPosition(UDim2.new(0, 2, 0.5, -7), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) end end) end
function CreateButton(Parent, Text, Callback) local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Purple; Btn.Size = UDim2.new(1, -10, 0, 35); Btn.Text = Text; Btn.TextColor3 = Color3.new(1,1,1); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Btn.MouseButton1Click:Connect(Callback) end
function CreateTextBox(Parent, Text, Default, Var) local Frame = Instance.new("Frame", Parent); Frame.BackgroundColor3 = Theme.Item; Frame.Size = UDim2.new(1, -10, 0, 35); local Label = Instance.new("TextLabel", Frame); Label.Text = "  "..Text; Label.TextColor3 = Theme.Text; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; local InputBox = Instance.new("TextBox", Frame); InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputBox.Position = UDim2.new(0.6, 0, 0.15, 0); InputBox.Size = UDim2.new(0.35, 0, 0.7, 0); InputBox.Font = Enum.Font.GothamSemibold; InputBox.TextSize = 12; InputBox.TextColor3 = Theme.Text; InputBox.Text = tostring(Default); InputBox.FocusLost:Connect(function() local val = tonumber(InputBox.Text); if val then getgenv()[Var] = val else InputBox.Text = tostring(getgenv()[Var]) end end); return InputBox end

-- Inject UI
local SeedBox = CreateTextBox(TargetPage, "Seed ID (Manual kalau Dropdown error)", getgenv().SelectedSeed, "SelectedSeed")
CreateTextBox(TargetPage, "Kiri X (Start)", getgenv().FarmStartX, "FarmStartX")
CreateTextBox(TargetPage, "Kanan X (End)", getgenv().FarmEndX, "FarmEndX")
CreateTextBox(TargetPage, "Bawah Y (Stop Farm)", getgenv().FarmBottomY, "FarmBottomY")
CreateToggle(TargetPage, "🚜 START AUTO PLANT FULL", "EnableAutoPlant")

-- ================================================= --
-- [[ LOGIC INTI: JALAN NATURAL + SCAN & PLANT ]]    --
-- ================================================= --

local RemotePlace = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")

if getgenv().KzoyzAutoPlantLoop then task.cancel(getgenv().KzoyzAutoPlantLoop) end

getgenv().KzoyzAutoPlantLoop = task.spawn(function()
    local walkDir = "Right" 
    local lastPlantedX = nil

    while task.wait(0.05) do
        if not getgenv().EnableAutoPlant then 
            lastPlantedX = nil -- Reset kalau dimatiin
            continue 
        end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if not hrp or not hum then continue end

        -- Cek Slot Seed
        local seedSlot = GetSlotByItemID(getgenv().SelectedSeed)
        if not seedSlot then
            warn("Bibit Habis! Auto Plant Berhenti.")
            getgenv().EnableAutoPlant = false
            hum:MoveTo(hrp.Position) -- Ngerem / Berhenti jalan
            continue
        end

        -- 1. Deteksi Grid Secara Real-Time (Tanpa Teleport)
        local currentGridX = math.floor(hrp.Position.X / getgenv().GridSize + 0.5)
        local currentGridY = math.floor(hrp.Position.Y / getgenv().GridSize + 0.5)

        -- Stop farming kalau udah nyentuh batas bawah tanah
        if currentGridY <= getgenv().FarmBottomY then
            print("Farming selesai sampai batas Y: " .. getgenv().FarmBottomY)
            getgenv().EnableAutoPlant = false
            hum:MoveTo(hrp.Position)
            continue
        end

        -- 2. TUKANG TANAM (Nembak remote otomatis pas nginjek grid baru)
        if currentGridX ~= lastPlantedX then
            local targetGrid = Vector2.new(currentGridX, currentGridY)
            pcall(function()
                RemotePlace:FireServer(targetGrid, seedSlot)
            end)
            lastPlantedX = currentGridX
        end

        -- 3. TUKANG JALAN (Ngeluarin perintah lari tanpa nge-Desync server)
        local targetGridX = (walkDir == "Right") and getgenv().FarmEndX or getgenv().FarmStartX
        
        -- Jalan natural pakai Humanoid:MoveTo ke ujung baris
        local targetWorldPos = Vector3.new(targetGridX * getgenv().GridSize, hrp.Position.Y, hrp.Position.Z)
        hum:MoveTo(targetWorldPos)

        -- 4. LOGIKA PUTAR BALIK & TURUN
        -- Kalau posisi aslinya udah nyampe / mentok di target (toleransi 0.5 biar gak bug)
        if math.abs(hrp.Position.X - targetWorldPos.X) <= 1 then
            hum:MoveTo(hrp.Position) -- Ngerem dulu sebentar
            task.wait(0.3)
            
            -- Balik arah
            if walkDir == "Right" then
                walkDir = "Left"
            else
                walkDir = "Right"
            end
            
            -- RESET lastPlantedX biar pas turun ke baris baru, dia langsung nanam lagi
            lastPlantedX = nil
            
            -- Biarkan game secara natural menjatuhkan karaktermu ke bawah (kalau blok di bawahnya kosong)
            -- Kita kasih delay dikit nunggu karakter jatuh ke Y berikutnya
            task.wait(0.5) 
        end
    end
end)
