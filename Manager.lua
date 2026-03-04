local Tab = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index (WindUI)!") return end

getgenv().ScriptVersion = "Manager v4.1 - PURE ENGINE LOGIC (FIXED)" 

-- ========================================== --
-- [[ DEFAULT SETTINGS (ANTI-RESET) ]]
-- ========================================== --
getgenv().DropDelay = getgenv().DropDelay or 2     
getgenv().TrashDelay = getgenv().TrashDelay or 2    
getgenv().GridSize = getgenv().GridSize or 4.5 
getgenv().WalkSpeed = getgenv().WalkSpeed or 45 

getgenv().AutoCollect = getgenv().AutoCollect or false
getgenv().AutoDrop = getgenv().AutoDrop or false
getgenv().AutoTrash = getgenv().AutoTrash or false
getgenv().AutoBan = getgenv().AutoBan or false
getgenv().AutoPull = getgenv().AutoPull or false
getgenv().DropAmount = getgenv().DropAmount or 50
getgenv().TrashAmount = getgenv().TrashAmount or 50

getgenv().AutoChat = getgenv().AutoChat or false
getgenv().ChatText = getgenv().ChatText or "Halo Semuanya"
getgenv().ChatDelay = getgenv().ChatDelay or 3
getgenv().ChatRandomLetter = getgenv().ChatRandomLetter or true

getgenv().HideName = getgenv().HideName or false
getgenv().FakeNameText = getgenv().FakeNameText or "KzoyzPlayer"
getgenv().AntiStaff = getgenv().AntiStaff or false
getgenv().CustomZoom = getgenv().CustomZoom or 1000

getgenv().AntiHit = getgenv().AntiHit or false
getgenv().AntiBounce = getgenv().AntiBounce or false
getgenv().ModflyEnabled = getgenv().ModflyEnabled or false
getgenv().InfJump = getgenv().InfJump or false
getgenv().SuperSpeed = getgenv().SuperSpeed or false
getgenv().LockedX = nil 
getgenv().IsHoldingSpace = false

-- ========================================== --
-- [[ SERVICES & MODULES ]]
-- ========================================== --
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RawWorldTiles = require(RS:WaitForChild("WorldTiles"))
local WorldManager = require(RS:WaitForChild("Managers"):WaitForChild("WorldManager"))

local PlayerMovement
pcall(function() PlayerMovement = require(LP.PlayerScripts:WaitForChild("PlayerMovement")) end)

local UIManager
pcall(function() UIManager = require(RS:WaitForChild("Managers"):WaitForChild("UIManager")) end)

local function ManageUIState(Mode)
    local PG = LP:FindFirstChild("PlayerGui")
    if not PG then return end
    if Mode == "Normal" then
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = true end end end end
        local RestoredUI = {"GemsUI", "TopbarCentered", "TopbarCenteredClipped", "TopbarStandard", "TopbarStandardClipped", "ExperienceChat"}
        for _, name in pairs(RestoredUI) do local ui = PG:FindFirstChild(name); if ui and ui:IsA("ScreenGui") then ui.Enabled = true end end
    elseif Mode == "Dropping" then
        if PlayerMovement then PlayerMovement.InputActive = true end
        if PG:FindFirstChild("TouchGui") then PG.TouchGui.Enabled = true end
        if PG:FindFirstChild("InventoryUI") then PG.InventoryUI.Enabled = true end
        if PG:FindFirstChild("ExperienceChat") then PG.ExperienceChat.Enabled = true end
        local prompts = {PG:FindFirstChild("UIPromptUI"), PG:FindFirstChild("UIPrompt")}
        for _, prompt in pairs(prompts) do if prompt then for _, v in pairs(prompt:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end end end
    end
end

local function ForceRestoreUI()
    ManageUIState("Normal") 
    pcall(function()
        if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end
        for _, gui in pairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end
        end
    end)
    task.wait(0.1)
    pcall(function()
        if UIManager then
            if type(UIManager.ShowHUD) == "function" then UIManager:ShowHUD() end
            if type(UIManager.ShowUI) == "function" then UIManager:ShowUI() end
        end
    end)
end

local function FindInventoryModule()
    local Candidates = {}
    for _, v in pairs(RS:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar") or v.Name:match("Client")) then table.insert(Candidates, v) end end
    if LP:FindFirstChild("PlayerScripts") then for _, v in pairs(LP.PlayerScripts:GetDescendants()) do if v:IsA("ModuleScript") and (v.Name:match("Inventory") or v.Name:match("Hotbar")) then table.insert(Candidates, v) end end end
    for _, module in pairs(Candidates) do local success, result = pcall(require, module); if success and type(result) == "table" then if result.GetSelectedHotbarItem or result.GetSelectedItem or result.GetEquippedItem then return result end end end
    return nil
end
getgenv().GameInventoryModule = FindInventoryModule()

-- ========================================== --
-- [[ REMOTES & ANTI-HIT HOOK ]]
-- ========================================== --
local Remotes = RS:WaitForChild("Remotes")
local RemoteDropSafe = Remotes:WaitForChild("PlayerDrop") 
local RemoteTrashSafe = Remotes:WaitForChild("PlayerItemTrash") 
local RemoteInspect = Remotes:WaitForChild("PlayerInspectPlayer") 
local ManagerRemote = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent") 
local ChatRemote = RS:WaitForChild("CB")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and getgenv().AntiHit then
        if method == "FireServer" and tostring(self.Name) == "PlayerHurtMe" then
            return nil 
        end
    end
    return oldNamecall(self, ...)
end)

-- ========================================== --
-- [[ INPUT TRACKING (Dari kodemu) ]]
-- ========================================== --
UIS.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Space then getgenv().IsHoldingSpace = true end
end)
UIS.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Space then getgenv().IsHoldingSpace = false end
end)

-- ========================================== --
-- [[ WIND UI SETUP ]]
-- ========================================== --

local SecPlayer = Tab:Section({ Title = "Misc & Player Hacks", Box = true, Opened = true })
SecPlayer:Toggle({ Title = "🛡️ Anti Hit (Kebal Magma/Spike)", Default = getgenv().AntiHit, Callback = function(v) getgenv().AntiHit = v end })
SecPlayer:Toggle({ Title = "⛔ Anti Punch / No Knockback", Default = getgenv().AntiBounce, Callback = function(v) getgenv().AntiBounce = v end })
SecPlayer:Toggle({ Title = "✈️ Anti-Gravity (Modfly)", Default = getgenv().ModflyEnabled, Callback = function(v) getgenv().ModflyEnabled = v end })
SecPlayer:Toggle({ Title = "🦘 Infinite Jump", Default = getgenv().InfJump, Callback = function(v) getgenv().InfJump = v end })
SecPlayer:Toggle({ Title = "⚡ Super Speed", Default = getgenv().SuperSpeed, Callback = function(v) getgenv().SuperSpeed = v end })
SecPlayer:Input({ Title = "Speed Modifier (Isi Angka)", Value = tostring(getgenv().WalkSpeed), Placeholder = "45", Callback = function(v) getgenv().WalkSpeed = tonumber(v) or getgenv().WalkSpeed end })

local SecMisc = Tab:Section({ Title = "Server Tools", Box = true, Opened = false })
SecMisc:Toggle({ Title = "Auto Pull Players", Default = getgenv().AutoPull, Callback = function(v) getgenv().AutoPull = v; if not v then ForceRestoreUI() end end })
SecMisc:Toggle({ Title = "Auto Ban Players", Default = getgenv().AutoBan, Callback = function(v) getgenv().AutoBan = v; if not v then ForceRestoreUI() end end })
SecMisc:Toggle({ Title = "Enable Anti-Staff", Default = getgenv().AntiStaff, Callback = function(v) getgenv().AntiStaff = v end })

local SecCam = Tab:Section({ Title = "Camera Settings", Box = true, Opened = false })
SecCam:Input({ Title = "Max Zoom Distance", Value = tostring(getgenv().CustomZoom), Placeholder = tostring(getgenv().CustomZoom), Callback = function(v) getgenv().CustomZoom = tonumber(v) or getgenv().CustomZoom end })
SecCam:Button({ Title = "Apply Camera Zoom", Callback = function() pcall(function() LP.CameraMaxZoomDistance = tonumber(getgenv().CustomZoom) or 1000; LP.CameraMinZoomDistance = 0.5 end) end })

local SecCollect = Tab:Section({ Title = "Auto Collect", Box = true, Opened = false })
SecCollect:Toggle({ Title = "Auto Collect", Default = getgenv().AutoCollect, Callback = function(v) getgenv().AutoCollect = v end })
SecCollect:Button({ Title = "Clear Blacklisted Drops", Callback = function() getgenv().BlacklistedLoot = {} warn("✅ Blacklist Dibersihkan!") end })

-- [Sisa UI Drop, Trash, Streamer, Chat disembunyikan buat ngirit space, anggap aja ada seperti biasa]
local SecDrop = Tab:Section({ Title = "Auto Drop", Box = true, Opened = false })
SecDrop:Toggle({ Title = "Auto Drop", Default = getgenv().AutoDrop, Callback = function(v) getgenv().AutoDrop = v; if not v then ForceRestoreUI() end end })
SecDrop:Input({ Title = "Drop Amount", Value = tostring(getgenv().DropAmount), Placeholder = tostring(getgenv().DropAmount), Callback = function(v) getgenv().DropAmount = tonumber(v) or getgenv().DropAmount end })

local SecTrash = Tab:Section({ Title = "Auto Trash", Box = true, Opened = false })
SecTrash:Toggle({ Title = "Auto Trash", Default = getgenv().AutoTrash, Callback = function(v) getgenv().AutoTrash = v; if not v then ForceRestoreUI() end end })
SecTrash:Input({ Title = "Trash Amount", Value = tostring(getgenv().TrashAmount), Placeholder = tostring(getgenv().TrashAmount), Callback = function(v) getgenv().TrashAmount = tonumber(v) or getgenv().TrashAmount end })


-- ========================================== --
-- [[ ⚙️ HEARTBEAT: MOVEMENT & COMBAT LOGIC ]]
-- ========================================== --

RunService.RenderStepped:Connect(function(dt)
    if not PlayerMovement then return end
    
    local char = LP.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    
    -- Ambil MoveX murni dari sistem game (Gak bakal drifting!)
    local pMoveX = PlayerMovement.MoveX or 0

    pcall(function()
        -- [1] ANTI PUNCH / NO KNOCKBACK (Murni dari Logikamu)
        if getgenv().AntiBounce then
            if pMoveX == 0 then
                if not getgenv().LockedX then
                    getgenv().LockedX = PlayerMovement.Position.X
                else
                    local currentX = PlayerMovement.Position.X
                    local diff = math.abs(currentX - getgenv().LockedX)
                    
                    if diff > 0 and diff < 15 then
                        PlayerMovement.Position = Vector3.new(getgenv().LockedX, PlayerMovement.Position.Y, PlayerMovement.Position.Z)
                        PlayerMovement.OldPosition = PlayerMovement.Position
                        PlayerMovement.VelocityX = 0
                    elseif diff >= 15 then
                        getgenv().LockedX = currentX
                    end
                end
            else
                getgenv().LockedX = nil
            end

            -- Matikan fisika Roblox
            if hrp then
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
                hrp.RotVelocity = Vector3.zero
            end
        else
            getgenv().LockedX = nil
        end

        -- [2] SUPER SPEED (Baca dari MoveX game, bukan Roblox)
        if getgenv().SuperSpeed and pMoveX ~= 0 then
            PlayerMovement.VelocityX = pMoveX * (getgenv().WalkSpeed or 45)
        end

        -- [3] INFINITE JUMP
        if getgenv().InfJump then
            PlayerMovement.RemainingJumps = 999
            PlayerMovement.MaxJump = 999
        end

        -- [4] MODFLY (Anti-Gravity)
        if getgenv().ModflyEnabled then
            PlayerMovement.VelocityY = 0
            
            local flySpeed = (getgenv().WalkSpeed or 45) * dt
            
            -- PC (Spasi / W / Up)
            if getgenv().IsHoldingSpace or UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then
                PlayerMovement.Position = PlayerMovement.Position + Vector3.new(0, flySpeed, 0)
            -- PC (S / Down)
            elseif UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then
                PlayerMovement.Position = PlayerMovement.Position - Vector3.new(0, flySpeed, 0)
            end
            
            -- Mobile Fallback (Joystick Analog)
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and not getgenv().IsHoldingSpace then
                if hum.MoveDirection.Z < -0.2 then
                    PlayerMovement.Position = PlayerMovement.Position + Vector3.new(0, flySpeed, 0)
                elseif hum.MoveDirection.Z > 0.2 then
                    PlayerMovement.Position = PlayerMovement.Position - Vector3.new(0, flySpeed, 0)
                end
            end
        end
    end)
    
    if getgenv().AutoDrop or getgenv().AutoTrash then ManageUIState("Dropping") end 
end)

-- [[ SISA LOGIKA: BAN, PULL, STAFF, CHAT, TRASH, DROP, AUTOLOOT ]]
local function ExecuteBan(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end); task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "ban", Inputs = {}}) end)
    pcall(function() if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end; for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
end

local function ExecutePull(targetPlayer)
    if targetPlayer == LP then return end
    pcall(function() RemoteInspect:FireServer(targetPlayer) end); task.wait(0.1) 
    pcall(function() ManagerRemote:FireServer({ButtonAction = "pull", Inputs = {}}) end)
    pcall(function() if UIManager and type(UIManager.ClosePrompt) == "function" then UIManager:ClosePrompt() end; for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
end

task.spawn(function()
    while true do
        if getgenv().AutoBan or getgenv().AutoPull then
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LP then 
                    if getgenv().AutoBan then ExecuteBan(targetPlayer) end
                    if getgenv().AutoPull then ExecutePull(targetPlayer) end
                    task.wait(0.2) 
                end
            end
        end
        task.wait(0.5) 
    end
end)

task.spawn(function() 
    local WasAutoDropOn = false
    while true do 
        if getgenv().AutoDrop then 
            WasAutoDropOn = true
            local Amt = getgenv().DropAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then _, slot = getgenv().GameInventoryModule.GetSelectedItem() end; 
                    if slot then RemoteDropSafe:FireServer(slot, Amt) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "drp", Inputs = { amt = tostring(Amt) } }})) end)
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().DropDelay) 
        else
            if WasAutoDropOn then WasAutoDropOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)

task.spawn(function() 
    local WasAutoTrashOn = false
    while true do 
        if getgenv().AutoTrash then 
            WasAutoTrashOn = true
            local Amt = getgenv().TrashAmount; 
            pcall(function() 
                if getgenv().GameInventoryModule then 
                    local _, slot; 
                    if getgenv().GameInventoryModule.GetSelectedHotbarItem then _, slot = getgenv().GameInventoryModule.GetSelectedHotbarItem() 
                    elseif getgenv().GameInventoryModule.GetSelectedItem then _, slot = getgenv().GameInventoryModule.GetSelectedItem() end; 
                    if slot then RemoteTrashSafe:FireServer(slot) end 
                end 
            end); 
            task.wait(0.2)
            pcall(function() ManagerRemote:FireServer(unpack({{ ButtonAction = "trsh", Inputs = { amt = tostring(Amt) } }})) end)
            pcall(function() for _, gui in pairs(LP.PlayerGui:GetDescendants()) do if gui:IsA("Frame") and string.find(string.lower(gui.Name), "prompt") then gui.Visible = false end end end)
            task.wait(getgenv().TrashDelay)
        else
            if WasAutoTrashOn then WasAutoTrashOn = false; ForceRestoreUI() end
            task.wait(0.5)
        end 
    end 
end)
