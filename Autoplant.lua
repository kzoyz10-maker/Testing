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

getgenv().ScriptVersion = "Auto Farm V28 (INTERNAL MAP HACK)"

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

-- AKSES LANGSUNG KE DATA MAP SERVER
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        
        if not getgenv()[Var] then
            pcall(function()
                local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
                if MyHitbox then 
                    MyHitbox.Anchored = false
                    MyHitbox.Velocity = Vector3.new(0,0,0) 
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
CreateToggle(TargetPage, "🚀 START V28 (MAP HACK PATHFINDER)", "EnableSmartHarvest")

-- ========================================== --
-- [[ TAHAP 1: BACA DATABASE SERVER ]]
-- ========================================== --
local function IsTileSolid(gridX, gridY)
    -- Kalau gak ada data di kordinat ini, berarti kosong (bisa dilewati)
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then 
        return false 
    end
    
    -- Cek isi kordinat (Layer 1 biasanya lantai tanah, Layer 2 ke atas bangunan/tanaman)
    for layer, tileData in pairs(RawWorldTiles[gridX][gridY]) do
        if layer > 1 then
            local tileName = type(tileData) == "table" and tileData[1] or tileData
            if type(tileName) == "string" then
                -- Abaikan kalau itu tanaman (sapling), karena bisa ditembus
                if string.find(string.lower(tileName), "sapling") then continue end
                -- Abaikan shadow/area markers
                if string.find(string.lower(tileName), "lock_area") then continue end
                
                -- Sisanya (Pagar, Tembok, Mesin) = BISA BIKIN NYANGKUT!
                return true
            end
        end
    end
    return false
end

-- ========================================== --
-- [[ TAHAP 2: BREADTH-FIRST SEARCH (PATHFINDING) ]]
-- ========================================== --
local function FindPath(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    
    local queue = {{x = startX, y = startY, path = {}}}
    local visited = {}
    visited[startX .. "," .. startY] = true

    local maxSearch = 400 -- Batas cari biar gak lag kalau kejauhan
    local searchCount = 0

    local directions = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1} -- Kanan, Kiri, Atas, Bawah
    }

    while #queue > 0 and searchCount < maxSearch do
        searchCount = searchCount + 1
        local current = table.remove(queue, 1)

        if current.x == targetX and current.y == targetY then
            return current.path
        end

        for _, dir in ipairs(directions) do
            local nextX = current.x + dir[1]
            local nextY = current.y + dir[2]
            local posKey = nextX .. "," .. nextY

            if not visited[posKey] and not IsTileSolid(nextX, nextY) then
                visited[posKey] = true
                local newPath = {unpack(current.path)}
                table.insert(newPath, {x = nextX, y = nextY})
                table.insert(queue, {x = nextX, y = nextY, path = newPath})
            end
        end
    end
    return nil -- Rute Buntu
end

-- ========================================== --
-- [[ TAHAP 3: EKSEKUSI PERGERAKAN JALUR ]]
-- ========================================== --
local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.floor((MyHitbox.Position.X / getgenv().GridSize) + 0.5)
    local myGridY = math.floor((MyHitbox.Position.Y / getgenv().GridSize) + 0.5)

    if myGridX == targetX and myGridY == targetY then return true end

    -- Hitung Rute!
    local route = FindPath(myGridX, myGridY, targetX, targetY)
    
    if not route then
        print("⚠️ Gak nemu jalan ke: X"..targetX.." Y"..targetY.." (Kepentok Objek)")
        return false
    end

    pcall(function() MyHitbox.Anchored = true end)

    -- Jalan ngikutin Rute yang udah dihitung AI
    for _, stepPos in ipairs(route) do
        if not getgenv().EnableSmartHarvest then break end
        
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        MyHitbox.CFrame = CFrame.new(pos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = pos end) end
        
        MyHitbox.Velocity = Vector3.new(0,0,0)
        task.wait(getgenv().StepDelay)
    end

    pcall(function() MyHitbox.Anchored = false end)
    return true
end

-- ========================================== --
-- [[ TAHAP 4: SCAN & FARM LOGIC ]]
-- ========================================== --
local SaplingsData = {}
local function ScanWorld()
    SaplingsData = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local tileName = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        
                        if type(tileName) == "string" and string.find(string.lower(tileName), "sapling") then
                            if tileInfo and tileInfo.at then
                                table.insert(SaplingsData, {x = x, y = y, name = tileName, at = tileInfo.at})
                            end
                        end
                    end
                end
            end
        end
    end
end

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
                        
                        local umurSekarang = workspace:GetServerTimeNow() - sapling.at
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
                    local umur = workspace:GetServerTimeNow() - sapling.at
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
