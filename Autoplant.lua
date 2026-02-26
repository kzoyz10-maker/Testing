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

getgenv().ScriptVersion = "Auto Farm V27 (SAFE GRID WALKER)"

-- ========================================== --
-- [[ KONFIGURASI ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().StepDelay = 0.08   
getgenv().BreakDelay = 0.15  
getgenv().EnableSmartHarvest = false

getgenv().AIDictionary = getgenv().AIDictionary or {}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        
        -- Reset Fisik saat dimatikan
        if not getgenv()[Var] then
            pcall(function()
                local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
                if MyHitbox then 
                    MyHitbox.Anchored = false
                    MyHitbox.Velocity = Vector3.new(0,0,0) 
                    MyHitbox.RotVelocity = Vector3.new(0,0,0)
                end
            end)
        end
        
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80) 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end
CreateToggle(TargetPage, "🚀 START V27 (SAFE WALKER)", "EnableSmartHarvest")

-- ========================================== --
-- [[ TAHAP 1: RADAR GRID 4 ARAH ]]
-- ========================================== --
local function IsCellEmpty(gridX, gridY, fixedZ)
    local centerPos = CFrame.new(gridX * getgenv().GridSize, gridY * getgenv().GridSize, fixedZ)
    
    -- Hitbox deteksi dibikin KECIL (2.5 studs) biar gak false alarm nyenggol balok tetangga
    local scanSize = Vector3.new(2.5, 2.5, 2.5) 
    
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {LP.Character, workspace:FindFirstChild("Hitbox"), workspace:FindFirstChild("HoverPart")}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local parts = workspace:GetPartBoundsInBox(centerPos, scanSize, params)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and p.CanCollide then
            return false -- ADA BALOK!
        end
    end
    return true -- KOSONG AMAN
end

local SaplingsData = {}
local function ScanWorld()
    SaplingsData = {}
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
                                        local details = rawget(fg, 2)
                                        if type(details) == "table" and rawget(details, "at") then
                                            table.insert(SaplingsData, {x = gridX, y = gridY, name = name, at = rawget(details, "at")})
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if #SaplingsData > 0 then return end
                end
            end
        end
    end
end

-- ========================================== --
-- [[ TAHAP 2: SMART STEPPING (NO NOCLIP) ]]
-- ========================================== --
local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.floor((MyHitbox.Position.X / getgenv().GridSize) + 0.5)
    local myGridY = math.floor((MyHitbox.Position.Y / getgenv().GridSize) + 0.5)

    if myGridX == targetX and myGridY == targetY then return true end

    -- Fungsi jalan 1 kotak yang SANGAT AMAN
    local function SafeStep(nextX, nextY)
        if not getgenv().EnableSmartHarvest then return false end
        
        if not IsCellEmpty(nextX, nextY, myZ) then 
            return false 
        end

        local pos = Vector3.new(nextX * getgenv().GridSize, nextY * getgenv().GridSize, myZ)
        MyHitbox.CFrame = CFrame.new(pos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = pos end) end
        
        MyHitbox.Velocity = Vector3.new(0,0,0)
        MyHitbox.RotVelocity = Vector3.new(0,0,0)
        
        myGridX = nextX
        myGridY = nextY
        task.wait(getgenv().StepDelay)
        return true
    end

    pcall(function() MyHitbox.Anchored = true end)

    local stuckCounter = 0
    while (myGridX ~= targetX or myGridY ~= targetY) and getgenv().EnableSmartHarvest do
        local moved = false
        
        -- PRIORITAS 1: SAMAKAN LANTAI (Y) DULU
        if myGridY ~= targetY then
            local dirY = targetY > myGridY and 1 or -1
            
            if SafeStep(myGridX, myGridY + dirY) then
                moved = true
            else
                local dirX = targetX > myGridX and 1 or -1
                if targetX == myGridX then dirX = 1 end 
                
                if SafeStep(myGridX + dirX, myGridY) then
                    moved = true
                elseif SafeStep(myGridX - dirX, myGridY) then 
                    moved = true
                end
            end
            
        -- PRIORITAS 2: JALAN LURUS (X) KALAU LANTAI UDAH SAMA
        else
            local dirX = targetX > myGridX and 1 or -1
            
            if SafeStep(myGridX + dirX, myGridY) then
                moved = true
            else
                -- Kalau nabrak tembok kecil, LOMPATIN
                if IsCellEmpty(myGridX, myGridY + 1, myZ) and IsCellEmpty(myGridX + dirX, myGridY + 1, myZ) then
                    SafeStep(myGridX, myGridY + 1)
                    SafeStep(myGridX + dirX, myGridY)
                    SafeStep(myGridX, myGridY - 1)
                    moved = true
                end
            end
        end

        -- ANTI STUCK: Menyerah kalau macet total
        if not moved then
            stuckCounter = stuckCounter + 1
            if stuckCounter > 5 then
                print("⚠️ Buntu total! AI skip tanaman ini buat cegah lag.")
                break
            end
        else
            stuckCounter = 0 
        end
    end

    pcall(function() MyHitbox.Anchored = false end)
    return myGridX == targetX and myGridY == targetY
end

-- ========================================== --
-- [[ TAHAP 3: THE EYE (AI LEARNING UI) ]]
-- ========================================== --
local function AIBelajarWaktu(sapling)
    local sampai = MoveSmartlyTo(sapling.x, sapling.y)
    if not sampai then return false end
    
    local timer = 0
    while timer < 30 do
        local hover = workspace:FindFirstChild("HoverPart")
        if hover then
            for _, v in pairs(hover:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text ~= "" then
                    local text = string.lower(v.Text)
                    if string.find(text, "grown") or string.find(text, "harvest") then
                        local jam = tonumber(string.match(text, "(%d+)h")) or 0
                        local menit = tonumber(string.match(text, "(%d+)m")) or 0
                        local detik = tonumber(string.match(text, "(%d+)s")) or 0
                        
                        local isReady = string.find(text, "harvest") or string.find(text, "100%%")
                        local sisaWaktuLayar = (jam * 3600) + (menit * 60) + detik
                        if isReady then sisaWaktuLayar = 0 end
                        
                        local umurSekarang = os.time() - sapling.at
                        local totalDurasi = umurSekarang + sisaWaktuLayar
                        totalDurasi = math.floor((totalDurasi + 5) / 10) * 10
                        
                        getgenv().AIDictionary[sapling.name] = totalDurasi
                        print("🎯 AI HAFAL! " .. sapling.name .. " butuh " .. totalDurasi .. " detik!")
                        return true
                    end
                end
            end
        end
        timer = timer + 1
        task.wait(0.1)
    end
    return false
end

-- ========================================== --
-- [[ TAHAP 4: EKSEKUSI ]]
-- ========================================== --
if getgenv().KzoyzAutoFarmLoop then task.cancel(getgenv().KzoyzAutoFarmLoop) end

getgenv().KzoyzAutoFarmLoop = task.spawn(function()
    while true do
        if getgenv().EnableSmartHarvest then
            ScanWorld()
            local targetPanen = {}

            for _, sapling in ipairs(SaplingsData) do
                if not getgenv().EnableSmartHarvest then break end
                if not getgenv().AIDictionary[sapling.name] then
                    AIBelajarWaktu(sapling)
                    task.wait(1) 
                end
                
                if getgenv().AIDictionary[sapling.name] then
                    local umur = os.time() - sapling.at
                    local targetMatang = getgenv().AIDictionary[sapling.name]
                    if umur >= targetMatang then
                        table.insert(targetPanen, sapling)
                    end
                end
            end
            
            for _, panen in ipairs(targetPanen) do
                if not getgenv().EnableSmartHarvest then break end
                local bisaJalan = MoveSmartlyTo(panen.x, panen.y)
                if bisaJalan then
                    task.wait(0.1)
                    pcall(function() 
                        local targetVec = Vector2.new(panen.x, panen.y)
                        if RemoteFist:IsA("RemoteEvent") then RemoteFist:FireServer(targetVec) 
                        else RemoteFist:InvokeServer(targetVec) end
                    end)
                    task.wait(getgenv().BreakDelay)
                end
            end
        end
        task.wait(1) 
    end
end)
