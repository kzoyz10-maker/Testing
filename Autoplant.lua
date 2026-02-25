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

getgenv().ScriptVersion = "Auto Farm V12 (STAGE N SCANNER)"

-- ========================================== --
-- [[ KONFIGURASI ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().StepDelay = 0.05   
getgenv().BreakDelay = 0.15  
getgenv().HitsPerBlock = 1   

-- INI KUNCINYA: Angka n saat tanaman siap panen
getgenv().HarvestStage = 3   

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

CreateToggle(TargetPage, "🚀 START AUTO HARVEST (V12 FAST & SMART)", "EnableSmartHarvest")

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
-- [[ 🧠 DETEKTOR TAHAP (STAGE N) ]]
-- ========================================== --
local function GetRipePlantsByStage()
    local ripePlants = {}
    local foundMapTable = false
    
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
                                        foundMapTable = true
                                        
                                        -- Cek Detail Tabel (isinya 'at' dan 'n')
                                        local details = rawget(fg, 2)
                                        if type(details) == "table" then
                                            local currentStage = rawget(details, "n")
                                            
                                            -- Kalau stage-nya udah 3 (atau lebih), berarti MATANG!
                                            if type(currentStage) == "number" and currentStage >= getgenv().HarvestStage then
                                                table.insert(ripePlants, {x = gridX, y = gridY, name = name})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if foundMapTable then return ripePlants end
                end
            end
        end
    end
    return ripePlants
end

-- ========================================== --
-- [[ LOGIKA AUTO FARM ]]
-- ========================================== --
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist") 

if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            local targetPlants = GetRipePlantsByStage()
            
            if #targetPlants > 0 then
                -- print("🌾 V12: Menemukan " .. #targetPlants .. " tanaman matang (Stage "..getgenv().HarvestStage.."). OTW Panen!")
                
                local HitboxFolder = workspace:FindFirstChild("Hitbox")
                local MyHitbox = HitboxFolder and HitboxFolder:FindFirstChild(LP.Name)
                
                if MyHitbox then
                    local startZ = MyHitbox.Position.Z
                    for _, plant in ipairs(targetPlants) do
                        if not getgenv().EnableSmartHarvest then break end
                        
                        -- Cuma jalan kalau beneran mateng!
                        WalkToGrid(plant.x, plant.y, startZ)
                        task.wait(0.1) 
                        
                        local targetVec = Vector2.new(plant.x, plant.y)
                        for i = 1, getgenv().HitsPerBlock do
                            if not getgenv().EnableSmartHarvest then break end
                            pcall(function() 
                                if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                                else RemoteFist:InvokeServer(targetVec) end
                            end)
                            task.wait(getgenv().BreakDelay)
                        end
                    end
                end
            else
                -- DIAM AJA! Nggak usah muter-muter kayak satpam.
                -- print("⏳ Bot standby... Menunggu tanaman matang.")
            end
        end
        task.wait(1.5) -- Cek memory tiap 1.5 detik
    end
end)
