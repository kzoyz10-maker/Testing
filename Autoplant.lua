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

getgenv().ScriptVersion = "Auto Farm V36 (ULTIMATE DATABASE)"

-- ========================================== --
-- [[ KONFIGURASI ]]
-- ========================================== --
getgenv().GridSize = 4.5
getgenv().WalkSpeed = 16     
getgenv().BreakDelay = 0.15  
getgenv().EnableSmartHarvest = false

getgenv().AIDictionary = getgenv().AIDictionary or {}

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

-- Ambil Manager Sesuai Kode Asli Game
local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))
local ItemsManager = require(RS:WaitForChild("Managers"):WaitForChild("ItemsManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

function CreateToggle(Parent, Text, Var) 
    local Btn = Instance.new("TextButton", Parent); Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); Btn.Size = UDim2.new(1, -10, 0, 45); Btn.Text = "  " .. Text; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 13; Btn.TextXAlignment = Enum.TextXAlignment.Left; 
    local IndBg = Instance.new("Frame", Btn); IndBg.Size = UDim2.new(0, 40, 0, 20); IndBg.Position = UDim2.new(1, -50, 0.5, -10); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30); 
    local Dot = Instance.new("Frame", IndBg); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = getgenv()[Var] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8); Dot.BackgroundColor3 = getgenv()[Var] and Color3.new(1,1,1) or Color3.fromRGB(100,100,100); 

    Btn.MouseButton1Click:Connect(function() 
        getgenv()[Var] = not getgenv()[Var]; 
        if getgenv()[Var] then 
            Dot:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.new(1,1,1); IndBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80) 
        else 
            Dot:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.2, true); Dot.BackgroundColor3 = Color3.fromRGB(100,100,100); IndBg.BackgroundColor3 = Color3.fromRGB(30,30,30) 
        end 
    end) 
end
CreateToggle(TargetPage, "🚀 START V36 (DECRYPTED DATABASE)", "EnableSmartHarvest")

-- ========================================== --
-- [[ TAHAP 1: DECRYPTOR & DATABASE RADAR ]]
-- ========================================== --
local BlockSolidityCache = {}

-- Fungsi bawaan game untuk bersihin akhiran "_sapling"
local function getBaseId(p11)
    if type(p11) == "string" then return p11:gsub("_sapling$", "") else return p11 end
end

local function IsTileSolid(gridX, gridY)
    if gridX < 0 or gridX > 100 then return true end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        
        -- TRANSLATE ANGKA JADI TEKS MENGGUNAKAN MAP GAME!
        local tileString = rawId
        if type(rawId) == "number" and WorldManager.NumberToStringMap then
            tileString = WorldManager.NumberToStringMap[rawId] or rawId
        end
        
        local nameStr = tostring(tileString):lower()
        
        -- Pengecualian mutlak (Tembus)
        if string.find(nameStr, "sapling") or string.find(nameStr, "bg") or string.find(nameStr, "air") then continue end
        
        -- Cek Memori Bot
        if BlockSolidityCache[nameStr] ~= nil then
            if BlockSolidityCache[nameStr] == true then return true end
            continue
        end

        local isSolid = false

        -- BACA DATABASE LANGSUNG (ItemsManager.ItemsData)
        local baseId = getBaseId(tileString)
        local itemData = ItemsManager.ItemsData[baseId]
        
        if itemData then
            local t = tostring(itemData.Type):lower()
            -- Cek parameter standar
            if t == "block" or t == "soil" or t == "wall" or t == "machine" or t == "solid" then
                isSolid = true
            end
            -- Cek parameter boolean dari tabel Tile
            if itemData.Tile and (itemData.Tile.Solid or itemData.Tile.Collidable) then
                isSolid = true
            end
        end

        BlockSolidityCache[nameStr] = isSolid
        if isSolid then return true end
    end
    return false
end

-- ========================================== --
-- [[ TAHAP 2: A-STAR (A*) SMOOTH ENGINE ]]
-- ========================================== --
local function FindPathAStar(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end

    local function heuristic(x, y) return math.abs(x - targetX) + math.abs(y - targetY) end

    local openSet = {}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    local startKey = startX .. "," .. startY
    table.insert(openSet, {x = startX, y = startY, key = startKey})
    gScore[startKey] = 0
    fScore[startKey] = heuristic(startX, startY)

    local maxIterations = 5000 
    local iterations = 0
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

    while #openSet > 0 do
        iterations = iterations + 1
        if iterations > maxIterations then break end

        local current = openSet[1]
        local currentIndex = 1
        for i = 2, #openSet do
            if fScore[openSet[i].key] < fScore[current.key] then
                current = openSet[i]
                currentIndex = i
            end
        end

        if current.x == targetX and current.y == targetY then
            local path = {}
            local currKey = current.key
            while cameFrom[currKey] do
                local node = cameFrom[currKey]
                table.insert(path, 1, {x = current.x, y = current.y})
                current = node
                currKey = node.x .. "," .. node.y
            end
            return path
        end

        table.remove(openSet, currentIndex)
        closedSet[current.key] = true

        for _, dir in ipairs(directions) do
            local nextX = current.x + dir[1]
            local nextY = current.y + dir[2]
            local nextKey = nextX .. "," .. nextY

            if nextX < 0 or nextX > 100 then continue end
            if closedSet[nextKey] then continue end

            local isTarget = (nextX == targetX and nextY == targetY)
            
            if not isTarget and IsTileSolid(nextX, nextY) then
                closedSet[nextKey] = true
                continue
            end

            local tentative_gScore = gScore[current.key] + 1
            if not gScore[nextKey] or tentative_gScore < gScore[nextKey] then
                cameFrom[nextKey] = current
                gScore[nextKey] = tentative_gScore
                fScore[nextKey] = tentative_gScore + heuristic(nextX, nextY)

                local inOpenSet = false
                for _, node in ipairs(openSet) do
                    if node.key == nextKey then inOpenSet = true; break end
                end
                if not inOpenSet then
                    table.insert(openSet, {x = nextX, y = nextY, key = nextKey})
                end
            end
        end
    end
    return nil 
end

-- ========================================== --
-- [[ TAHAP 3: LERP MOVEMENT ]]
-- ========================================== --
local function SmoothWalkTo(targetPos)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local startPos = MyHitbox.Position
    local dist = (Vector2.new(startPos.X, startPos.Y) - Vector2.new(targetPos.X, targetPos.Y)).Magnitude 
    
    local duration = dist / getgenv().WalkSpeed
    if duration <= 0 then return true end
    
    local t = 0
    while t < duration do
        if not getgenv().EnableSmartHarvest then return false end
        local dt = RunService.Heartbeat:Wait()
        t = t + dt
        
        local alpha = math.clamp(t / duration, 0, 1)
        local currentPos = startPos:Lerp(targetPos, alpha)
        
        MyHitbox.CFrame = CFrame.new(currentPos)
        if PlayerMovement then pcall(function() PlayerMovement.Position = currentPos end) end
    end
    
    MyHitbox.CFrame = CFrame.new(targetPos)
    if PlayerMovement then pcall(function() PlayerMovement.Position = targetPos end) end
    return true
end

local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.floor((MyHitbox.Position.X / getgenv().GridSize) + 0.5)
    local myGridY = math.floor((MyHitbox.Position.Y / getgenv().GridSize) + 0.5)

    if myGridX == targetX and myGridY == targetY then return true end

    local route = FindPathAStar(myGridX, myGridY, targetX, targetY)
    if not route then return false end

    for _, stepPos in ipairs(route) do
        if not getgenv().EnableSmartHarvest then break end
        local pos = Vector3.new(stepPos.x * getgenv().GridSize, stepPos.y * getgenv().GridSize, myZ)
        if not SmoothWalkTo(pos) then return false end
    end

    return true
end

-- ========================================== --
-- [[ TAHAP 4: FARM LOGIC ]]
-- ========================================== --
local SaplingsData = {}
local function ScanWorld()
    SaplingsData = {}
    for x, yCol in pairs(RawWorldTiles) do
        if type(yCol) == "table" then
            for y, layers in pairs(yCol) do
                if type(layers) == "table" then
                    for layer, data in pairs(layers) do
                        local rawId = type(data) == "table" and data[1] or data
                        local tileInfo = type(data) == "table" and data[2] or nil
                        
                        -- DECRYPT UNTUK DETEKSI SAPLING!
                        local tileString = rawId
                        if type(rawId) == "number" and WorldManager.NumberToStringMap then
                            tileString = WorldManager.NumberToStringMap[rawId] or rawId
                        end
                        
                        if type(tileString) == "string" and string.find(string.lower(tileString), "sapling") then
                            if tileInfo and tileInfo.at then
                                table.insert(SaplingsData, {x = x, y = y, name = tileString, at = tileInfo.at})
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
