-- ========================================== --
-- [[ KZOYZ UTILITY: ESP & GROWSCAN MODAL ]]
-- ========================================== --
local TargetPage = ...
if not TargetPage then warn("Module harus di-load dari Kzoyz Index!") return end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- Ambil Data buat Growscan
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

getgenv().EnableESPDrops = false
getgenv().AIDictionary = getgenv().AIDictionary or {}

-- ========================================== --
-- [[ 1. SISTEM ESP DROPS & GEMS ]]
-- ========================================== --
function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(180, 80, 255) -- Warna Ungu buat ESP
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

CreateToggle(TargetPage, "👁️ TAMPILKAN ESP (Drops & Gems)", "EnableESPDrops")

-- Loop ESP
task.spawn(function()
    while task.wait(0.5) do
        local containers = { workspace:FindFirstChild("Drops"), workspace:FindFirstChild("Gems") }
        
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    local part = item:IsA("Model") and item.PrimaryPart or (item:IsA("BasePart") and item or nil)
                    
                    if part then
                        local existingESP = part:FindFirstChild("KzoyzESP_UI")
                        
                        if getgenv().EnableESPDrops then
                            if not existingESP then
                                local bb = Instance.new("BillboardGui", part)
                                bb.Name = "KzoyzESP_UI"
                                bb.Size = UDim2.new(0, 150, 0, 20)
                                bb.StudsOffset = Vector3.new(0, 1.5, 0)
                                bb.AlwaysOnTop = true
                                
                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1, 0, 1, 0)
                                txt.BackgroundTransparency = 1
                                -- Gems warnanya Biru Cyan, Drops warnanya Hijau Terang
                                txt.TextColor3 = item.Parent.Name == "Gems" and Color3.fromRGB(50, 200, 255) or Color3.fromRGB(100, 255, 100)
                                txt.TextStrokeTransparency = 0
                                txt.Font = Enum.Font.GothamBold
                                txt.TextSize = 11
                                txt.Text = "⬇ " .. item.Name
                            end
                        else
                            if existingESP then existingESP:Destroy() end
                        end
                    end
                end
            end
        end
    end
end)

-- ========================================== --
-- [[ 2. MODAL GROWSCAN (POPUP SCANNER) ]]
-- ========================================== --
local GuiService = pcall(function() return CoreGui end) and CoreGui or LP:WaitForChild("PlayerGui")
if GuiService:FindFirstChild("KzoyzGrowscanModal") then GuiService.KzoyzGrowscanModal:Destroy() end

local ScreenGui = Instance.new("ScreenGui", GuiService)
ScreenGui.Name = "KzoyzGrowscanModal"

local ModalFrame = Instance.new("Frame", ScreenGui)
ModalFrame.Size = UDim2.new(0, 350, 0, 400)
ModalFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
ModalFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ModalFrame.Visible = false
ModalFrame.Active = true
ModalFrame.Draggable = true -- Bisa digeser-geser

local UIStroke = Instance.new("UIStroke", ModalFrame)
UIStroke.Color = Color3.fromRGB(100, 100, 100)
UIStroke.Thickness = 2

local Title = Instance.new("TextLabel", ModalFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "📊 LIVE GROWSCAN SERVER"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16

local ScanBtn = Instance.new("TextButton", ModalFrame)
ScanBtn.Size = UDim2.new(1, -20, 0, 35)
ScanBtn.Position = UDim2.new(0, 10, 0, 50)
ScanBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 255)
ScanBtn.Text = "🔄 SCAN TANAMAN SEKARANG"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12

local ScrollList = Instance.new("ScrollingFrame", ModalFrame)
ScrollList.Size = UDim2.new(1, -20, 1, -100)
ScrollList.Position = UDim2.new(0, 10, 0, 95)
ScrollList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollList.ScrollBarThickness = 4
local ListLayout = Instance.new("UIListLayout", ScrollList)
ListLayout.Padding = UDim.new(0, 5)

-- Logika Scan Data Waktu
local function DeepFindGrowTime(tbl)
    if type(tbl) ~= "table" then return nil end
    for k, v in pairs(tbl) do
        if type(v) == "number" and type(k) == "string" then
            local kl = k:lower()
            if kl:find("grow") or kl:find("time") or kl:find("harvest") or kl:find("duration") or kl:find("age") then
                if v > 0 then return v end
            end
        elseif type(v) == "table" then
            local res = DeepFindGrowTime(v)
            if res then return res end
        end
    end
    return nil
end

local function GetExactGrowTime(saplingName)
    if getgenv().AIDictionary[saplingName] then return getgenv().AIDictionary[saplingName] end
    pcall(function()
        local baseId = string.gsub(saplingName, "_sapling", "")
        local itemData = ItemsManager.ItemsData[baseId] or ItemsManager.ItemsData[saplingName]
        if itemData then
            local foundTime = DeepFindGrowTime(itemData)
            if foundTime then getgenv().AIDictionary[saplingName] = foundTime end
        end
    end)
    return getgenv().AIDictionary[saplingName]
end

ScanBtn.MouseButton1Click:Connect(function()
    -- Bersihkan list lama
    for _, child in ipairs(ScrollList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    ScanBtn.Text = "⏳ SCANNING..."
    task.wait(0.1)

    local totalPlants = 0
    local readyPlants = 0
    local ySize = 0

    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local rawId = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        
                        local tileString = type(rawId) == "number" and (WorldManager.NumberToStringMap[rawId] or rawId) or rawId
                        
                        if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") and tileInfo and tileInfo.at then
                            totalPlants = totalPlants + 1
                            
                            local targetMatang = GetExactGrowTime(tileString) or 120 -- Default 2 menit kalau gagal baca DB
                            local umurAsli = math.max(os.time() - tileInfo.at, workspace:GetServerTimeNow() - tileInfo.at)
                            local sisaDetik = math.floor(targetMatang - umurAsli)
                            
                            local isReady = sisaDetik <= 0
                            if isReady then readyPlants = readyPlants + 1 end
                            
                            local statusText = isReady and "✅ SIAP PANEN!" or "⏳ Sisa: " .. sisaDetik .. " detik"
                            local textColor = isReady and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 50)
                            
                            local ItemBox = Instance.new("Frame", ScrollList)
                            ItemBox.Size = UDim2.new(1, 0, 0, 30)
                            ItemBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            
                            local Lbl = Instance.new("TextLabel", ItemBox)
                            Lbl.Size = UDim2.new(1, -10, 1, 0)
                            Lbl.Position = UDim2.new(0, 10, 0, 0)
                            Lbl.BackgroundTransparency = 1
                            Lbl.Text = string.format("[%d, %d] %s - %s", x, y, string.upper(string.gsub(tileString, "_sapling", "")), statusText)
                            Lbl.TextColor3 = textColor
                            Lbl.Font = Enum.Font.Gotham
                            Lbl.TextSize = 11
                            Lbl.TextXAlignment = Enum.TextXAlignment.Left
                            
                            ySize = ySize + 35
                        end
                    end
                end
            end
        end
    end
    
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, ySize)
    ScanBtn.Text = string.format("🔄 SCAN ULANG (%d Siap / %d Total)", readyPlants, totalPlants)
end)

-- Tombol buat buka Modal di Menu UI
local OpenModalBtn = Instance.new("TextButton", TargetPage)
OpenModalBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
OpenModalBtn.Size = UDim2.new(1, -10, 0, 40)
OpenModalBtn.Text = "📊 BUKA MODAL GROWSCAN"
OpenModalBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
OpenModalBtn.Font = Enum.Font.GothamBold
OpenModalBtn.TextSize = 13
local UIStrokeBtn = Instance.new("UIStroke", OpenModalBtn); UIStrokeBtn.Color = Color3.fromRGB(255, 215, 0); UIStrokeBtn.Thickness = 1

OpenModalBtn.MouseButton1Click:Connect(function()
    ModalFrame.Visible = not ModalFrame.Visible
end)
CloseBtn.MouseButton1Click:Connect(function()
    ModalFrame.Visible = false
end)
