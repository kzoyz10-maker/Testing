local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Auto Clear v2.0 - FULL SMART SCAN" 

-- ========================================== --
-- [[ DEFAULT SETTINGS ]]
-- ========================================== --
getgenv().EnableAutoClear = getgenv().EnableAutoClear or false
getgenv().ClearDelay = getgenv().ClearDelay or 0.15 
getgenv().GridSize = 4.5

-- ========================================== --
-- [[ SERVICES & MANAGERS ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local RemoteBreak = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

-- ========================================== --
-- [[ DETEKSI BLOK / BACKGROUND YG BISA DIHANCURKAN ]]
-- ========================================== --
local function IsTileBreakable(gridX, gridY)
    -- Kalau di luar map, skip
    if gridX < 0 or gridX > 100 or gridY < 0 then return false end
    if not RawWorldTiles[gridX] or not RawWorldTiles[gridX][gridY] then return false end
    
    local hasBreakable = false

    -- Cek setiap layer (Blok depan, Background, dll)
    for layer, data in pairs(RawWorldTiles[gridX][gridY]) do
        local rawId = type(data) == "table" and data[1] or data
        local tileString = rawId
        
        -- Konversi ID angka ke nama (jika ada)
        if type(rawId) == "number" and WorldManager.NumberToStringMap then 
            tileString = WorldManager.NumberToStringMap[rawId] or rawId 
        end
        
        local nameStr = tostring(tileString):lower()
        
        -- JANGAN dihancurkan kalau ini udara, air, pintu, atau bedrock
        if nameStr:find("air") or nameStr:find("water") or nameStr:find("door") or nameStr:find("bedrock") or nameStr == "0" then
            -- Skip yang ini
        else
            -- Kalau ada blok atau background selain daftar hitam di atas, berarti BISA dihancurin
            hasBreakable = true
        end
    end
    
    return hasBreakable
end

-- ========================================== --
-- [[ UI SECTION: AUTO CLEAR ]]
-- ========================================== --
local SecClear = Tab:Section({ Title = "🧨 Auto Clear World (Smart Scan)", Box = true, Opened = true })

SecClear:Toggle({ 
    Title = "▶ START AUTO CLEAR", 
    Desc = "Otomatis scan map & hancurkan rapi dari atas ke bawah",
    Default = getgenv().EnableAutoClear, 
    Callback = function(v) 
        getgenv().EnableAutoClear = v 
        if not v then
            -- Kembalikan kontrol normal kalau dimatikan
            if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
        end
    end 
})

SecClear:Input({ 
    Title = "Break Delay (Detik)", 
    Value = tostring(getgenv().ClearDelay), 
    Placeholder = tostring(getgenv().ClearDelay), 
    Callback = function(v) getgenv().ClearDelay = tonumber(v) or getgenv().ClearDelay end 
})

-- ========================================== --
-- [[ LOGIKA UTAMA: AUTO CLEAR ZIG-ZAG ]]
-- ========================================== --
task.spawn(function()
    while true do
        if getgenv().EnableAutoClear then
            local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name) or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
            
            if MyHitbox then
                local currZ = MyHitbox.Position.Z

                -- Matikan input manual player biar bot bisa jalan mulus
                if PlayerMovement then pcall(function() PlayerMovement.InputActive = false end) end

                -- [!] OTOMATIS SCAN DARI Y TERTINGGI (100) KE TERENDAH (0)
                for y = 100, 0, -1 do 
                    if not getgenv().EnableAutoClear then break end
                    
                    -- Sistem Zig-Zag (X 0 -> 100, layer bawahnya X 100 -> 0)
                    local isEven = (y % 2 == 0)
                    local startX = isEven and 0 or 100
                    local endX = isEven and 100 or 0
                    local step = isEven and 1 or -1
                    
                    for x = startX, endX, step do
                        if not getgenv().EnableAutoClear then break end
                        
                        -- Cek otomatis apakah di kordinat ini ada yang bisa dipukul (Blok/BG)
                        if IsTileBreakable(x, y) then
                            -- Modfly: Melayang persis 1 grid di atas bloknya
                            local targetPos = Vector3.new(x * getgenv().GridSize, (y + 1) * getgenv().GridSize, currZ)
                            
                            if PlayerMovement then 
                                pcall(function() 
                                    PlayerMovement.Position = targetPos
                                    PlayerMovement.VelocityX = 0 
                                    PlayerMovement.VelocityY = 0 
                                    PlayerMovement.VelocityZ = 0 
                                    PlayerMovement.Grounded = true
                                end)
                            else
                                MyHitbox.CFrame = CFrame.new(targetPos)
                            end
                            
                            task.wait(0.05) -- Stabilkan posisi
                            
                            -- Hajar bloknya
                            local breakTarget = Vector2.new(x, y)
                            pcall(function()
                                if RemoteBreak:IsA("RemoteEvent") then 
                                    RemoteBreak:FireServer(breakTarget) 
                                else 
                                    RemoteBreak:InvokeServer(breakTarget) 
                                end
                            end)
                            
                            -- Tunggu delay sebelum mukul blok selanjutnya
                            task.wait(getgenv().ClearDelay)
                        end
                    end
                end
                
                -- Selesai nge-clear seluruh map
                getgenv().EnableAutoClear = false
                if PlayerMovement then pcall(function() PlayerMovement.InputActive = true end) end
                WindUI:Notify({ Title = "Auto Clear Selesai", Content = "Semua blok dan background telah rata dengan tanah!", Duration = 5 })
            end
        end
        task.wait(1)
    end
end)
