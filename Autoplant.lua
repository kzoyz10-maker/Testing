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

getgenv().ScriptVersion = "Auto Farm V11 (UI TEXT SCANNER)"

-- ========================================== --
-- [[ KONFIGURASI ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().StepDelay = 0.05   
getgenv().BreakDelay = 0.15  
getgenv().HitsPerBlock = 1   

getgenv().EnableSmartHarvest = false

-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ UI SETUP ]]
-- ========================================== --
local Theme = { Item = Color3.fromRGB(45, 45, 45), Text = Color3.fromRGB(255, 255, 255), Red = Color3.fromRGB(255, 80, 80) }

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Theme.Item; Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Theme.Text; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Theme.Red 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end

CreateToggle(TargetPage, "🚀 START AUTO HARVEST (V11 UI SCAN)", "EnableSmartHarvest")

-- ========================================== --
-- [[ MODFLY SYSTEM ]]
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
    if getgenv().EnableSmartHarvest then
        local HitboxFolder = workspace:FindFirstChild("Hitbox")
        local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
        if MyHitbox then getgenv().AirPlatform.CFrame = CFrame.new(MyHitbox.Position.X, MyHitbox.Position.Y - (getgenv().GridSize / 2), MyHitbox.Position.Z) end
        if PlayerMovement then pcall(function() PlayerMovement.VelocityY = 0; PlayerMovement.Grounded = true end) end
    else
        getgenv().AirPlatform.CFrame = CFrame.new(0, -9999, 0)
    end
end)

local function WalkToGrid(tX, tY, startZ)
    local HitboxFolder = workspace:FindFirstChild("Hitbox")
    local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
    if not MyHitbox then return end

    local currentX = math.floor(MyHitbox.Position.X / getgenv().GridSize + 0.5)
    local currentY = math.floor(MyHitbox.Position.Y / getgenv().GridSize + 0.5)

    local timeout = 0 
    while (currentX ~= tX or currentY ~= tY) and timeout < 50 do
        if not getgenv().EnableSmartHarvest then break end
        if currentX ~= tX then currentX = currentX + (tX > currentX and 1 or -1)
        elseif currentY ~= tY then currentY = currentY + (tY > currentY and 1 or -1) end
        
        local newWorldPos = Vector3.new(currentX * getgenv().GridSize, currentY * getgenv().GridSize, startZ)
        MyHitbox.CFrame = CFrame.new(newWorldPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = newWorldPos end) end
        
        timeout = timeout + 1
        task.wait(getgenv().StepDelay)
    end
end

-- ========================================== --
-- [[ 👁️ SISTEM MEMBACA UI (UI SCANNER) ]]
-- ========================================== --
local function GetAllSaplingLocations()
    local saplings = {}
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and not isreadonly(obj) then
            local sX, col = next(obj)
            if type(sX) == "number" and type(col) == "table" then
                local sY, blockData = next(col)
                if type(sY) == "number" and type(blockData) == "table" then
                    for gridX, yCol in pairs(obj) do
                        if type(gridX) ~= "number" or type(yCol) ~= "table" then break end
                        for gridY, bData in pairs(yCol) do
                            if type(gridY) == "number" and type(bData) == "table" then
                                local fg = rawget(bData, 1) 
                                if type(fg) == "table" then
                                    local name = rawget(fg, 1)
                                    if type(name) == "string" and string.find(string.lower(name), "sapling") then
                                        table.insert(saplings, {x = gridX, y = gridY, name = name})
                                    end
                                end
                            end
                        end
                    end
                    if #saplings > 0 then return saplings end
                end
            end
        end
    end
    return saplings
end

-- Fungsi ini bertugas ngebaca semua Text di layar (PlayerGui & HoverPart)
local function IsUI100Percent()
    local labelsToScan = {}
    
    -- 1. Ambil UI dari Layar Player
    for _, obj in pairs(LP.PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            table.insert(labelsToScan, obj)
        end
    end
    
    -- 2. Ambil UI dari HoverPart (Kadang gamenya nempel UI di Workspace)
    local hoverPart = workspace:FindFirstChild("HoverPart")
    if hoverPart then
        for _, obj in pairs(hoverPart:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                table.insert(labelsToScan, obj)
            end
        end
    end
    
    -- Cek satu-satu tulisannya
    for _, label in ipairs(labelsToScan) do
        local txt = string.lower(label.Text)
        if string.find(txt, "100%% grown") or string.find(txt, "punch to harvest") then
            return true -- BENAR! SUDAH MATANG!
        end
    end
    
    return false -- BELUM MATANG (atau UI belum muncul)
end

-- ========================================== --
-- [[ LOGIKA AUTO FARM ]]
-- ========================================== --
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist") 

if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            local targetPlants = GetAllSaplingLocations()
            
            if #targetPlants > 0 then
                local HitboxFolder = workspace:FindFirstChild("Hitbox")
                local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
                
                if MyHitbox then
                    local startZ = MyHitbox.Position.Z
                    for _, plant in ipairs(targetPlants) do
                        if not getgenv().EnableSmartHarvest then break end
                        
                        -- 1. Jalan ke lokasi Bibit
                        WalkToGrid(plant.x, plant.y, startZ)
                        
                        -- 2. Tunggu 0.2 Detik biar kotak UI Hijaunya muncul
                        task.wait(0.2) 
                        
                        -- 3. BACA UI LAYAR!
                        if IsUI100Percent() then
                            print("✅ V11: Teks '100% Grown' terdeteksi! Memanen " .. plant.name)
                            local targetVec = Vector2.new(plant.x, plant.y)
                            for i = 1, getgenv().HitsPerBlock do
                                if not getgenv().EnableSmartHarvest then break end
                                pcall(function() 
                                    if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                                    else RemoteFist:InvokeServer(targetVec) end
                                end)
                                task.wait(getgenv().BreakDelay)
                            end
                        else
                            -- Kalau gagal, berarti tulisan masih "X% Grown", tinggalin.
                            -- print("❌ V11: Belum panen, skip!")
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)
