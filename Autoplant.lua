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

getgenv().ScriptVersion = "Auto Farm V20 (FIXED OMNISCIENT AI)"

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
local RemoteFist = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

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
CreateToggle(TargetPage, "🚀 START V20 (APEX PREDATOR)", "EnableSmartHarvest")

-- ========================================== --
-- [[ TAHAP 1: SCANNER (FIXED) ]]
-- ========================================== --
local SaplingsData = {}
local CollisionMap = {}

local function ScanWorld()
    SaplingsData = {}
    CollisionMap = {}
    
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and not isreadonly(obj) then
            local sX, col = next(obj)
            if type(sX) == "number" and type(col) == "table" then
                local sY, blockData = next(col)
                if type(sY) == "number" and type(blockData) == "table" then
                    
                    local foundValidMap = false
                    for gridX, yCol in pairs(obj) do
                        if type(gridX) ~= "number" or type(yCol) ~= "table" then break end
                        CollisionMap[gridX] = CollisionMap[gridX] or {}
                        
                        for gridY, bData in pairs(yCol) do
                            if type(gridY) == "number" and type(bData) == "table" then
                                local fg = rawget(bData, 1) 
                                if type(fg) == "table" then
                                    local name = rawget(fg, 1)
                                    if type(name) == "string" then
                                        foundValidMap = true
                                        if string.find(string.lower(name), "sapling") then
                                            local details = rawget(fg, 2)
                                            if type(details) == "table" and rawget(details, "at") then
                                                table.insert(SaplingsData, {
                                                    x = gridX, y = gridY, 
                                                    name = name, at = rawget(details, "at")
                                                })
                                            end
                                        else
                                            CollisionMap[gridX][gridY] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    -- HANYA BERHENTI SCAN JIKA BENAR-BENAR MENDAPATKAN MAP YANG ADA ISINYA
                    if foundValidMap and #SaplingsData > 0 then return end
                end
            end
        end
    end
end

-- ========================================== --
-- [[ TAHAP 2: OTAK PATHFINDING ]]
-- ========================================== --
local function FindSmartPath(startX, startY, targetX, targetY)
    if startX == targetX and startY == targetY then return {} end
    
    local queue = { {x = startX, y = startY, path = {}} }
    local visited = {}
    visited[startX .. "," .. startY] = true
    
    local dirs = { {1,0}, {-1,0}, {0,1}, {0,-1} }
    local maxSearch = 2500 
    local count = 0
    
    while #queue > 0 do
        count = count + 1
        if count > maxSearch then break end
        
        local curr = table.remove(queue, 1)
        
        for _, d in ipairs(dirs) do
            local nx = curr.x + d[1]
            local ny = curr.y + d[2]
            local key = nx .. "," .. ny
            
            if nx == targetX and ny == targetY then
                local finalPath = {}
                for _, p in ipairs(curr.path) do table.insert(finalPath, p) end
                table.insert(finalPath, {x = nx, y = ny})
                return finalPath
            end
            
            local isSolid = CollisionMap[nx] and CollisionMap[nx][ny]
            if not visited[key] and not isSolid then
                visited[key] = true
                local newPath = {}
                for _, p in ipairs(curr.path) do table.insert(newPath, p) end
                table.insert(newPath, {x = nx, y = ny})
                table.insert(queue, {x = nx, y = ny, path = newPath})
            end
        end
    end
    return nil 
end

-- ========================================== --
-- [[ TAHAP 3: SISTEM BERJALAN & GHOST-STEP ]]
-- ========================================== --
local function MoveSmartlyTo(targetX, targetY)
    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)
    if not MyHitbox then return false end
    
    local myZ = MyHitbox.Position.Z
    local myGridX = math.floor((MyHitbox.Position.X / getgenv().GridSize) + 0.5)
    local myGridY = math.floor((MyHitbox.Position.Y / getgenv().GridSize) + 0.5)
    
    if myGridX == targetX and myGridY == targetY then return true end
    
    print("🗺️ AI mencari rute dari ("..myGridX..","..myGridY..") menuju ("..targetX..","..targetY..")")
    local safePath = FindSmartPath(myGridX, myGridY, targetX, targetY)
    
    if safePath then
        print("✅ Rute Aman Ditemukan! Menjalankan " .. #safePath .. " langkah...")
        for _, step in ipairs(safePath) do
            if not getgenv().EnableSmartHarvest then break end
            local nextRealPos = Vector3.new(step.x * getgenv().GridSize, step.y * getgenv().GridSize, myZ)
            MyHitbox.CFrame = CFrame.new(nextRealPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = nextRealPos end) end
            task.wait(getgenv().StepDelay)
        end
        return true
    else
        warn("⚠️ Jalan Buntu secara Logika! Menggunakan [GHOST-STEP] Paksa perlahan...")
        local dx = (targetX > myGridX) and 1 or (targetX < myGridX and -1 or 0)
        local dy = (targetY > myGridY) and 1 or (targetY < myGridY and -1 or 0)
        
        local tempX = myGridX
        local tempY = myGridY
        
        while tempX ~= targetX or tempY ~= targetY do
            if not getgenv().EnableSmartHarvest then break end
            if tempX ~= targetX then tempX = tempX + dx end
            if tempY ~= targetY then tempY = tempY + dy end
            
            local nextRealPos = Vector3.new(tempX * getgenv().GridSize, tempY * getgenv().GridSize, myZ)
            MyHitbox.CFrame = CFrame.new(nextRealPos)
            if PlayerMovement then pcall(function() PlayerMovement.Position = nextRealPos end) end
            task.wait(0.15) 
        end
        return true
    end
end

-- ========================================== --
-- [[ TAHAP 4: THE EYE (AI LEARNING UI) ]]
-- ========================================== --
local function AIBelajarWaktu(sapling)
    print("🧠 AI melihat '" .. sapling.name .. "' untuk pertama kali. Sedang mendekat...")
    
    local sampai = MoveSmartlyTo(sapling.x, sapling.y)
    if not sampai then return false end
    
    print("👀 Sampai di lokasi! Menunggu UI muncul...")
    
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
                        print("🎯 AI HAFAL! " .. sapling.name .. " matang dalam " .. totalDurasi .. " detik!")
                        return true
                    end
                end
            end
        end
        timer = timer + 1
        task.wait(0.1)
    end
    
    warn("❌ UI tidak muncul atau gagal terbaca!")
    return false
end

-- ========================================== --
-- [[ TAHAP 5: EKSEKUSI ]]
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
                
                print("🌾 PANEN TIME! Menuju ke " .. panen.name)
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
