local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index!") return end

-- ==========================================
-- SETUP VARIABLES & SERVICES
-- ==========================================
local RS = game:GetService("ReplicatedStorage")
local queue_on_tp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or getgenv().queue_on_teleport

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"

getgenv().TargetWarpWorld = getgenv().TargetWarpWorld or "buy"
getgenv().EnableAutoWarp = getgenv().EnableAutoWarp or false
getgenv().CancelWarp = false -- Variabel darurat buat ngebatalin

-- ==========================================
-- SISTEM AUTO-LOAD (MEMBACA FILE)
-- ==========================================
local autoLoadPath = "WindUI/KzoyzHub/AutoLoad.txt"

local function GetAutoLoad()
    if isfile and isfile(autoLoadPath) and readfile then
        local saved = readfile(autoLoadPath)
        if saved and saved ~= "" then return saved end
    end
    return "None"
end

local function SetAutoLoad(name)
    if writefile then writefile(autoLoadPath, name) end
end

-- ==========================================
-- FUNGSI UTAMA UNTUK WARP
-- ==========================================
local function ExecuteWarp()
    task.spawn(function()
        local targetWorld = getgenv().TargetWarpWorld
        if not targetWorld or targetWorld == "" then
            warn("Nama World masih kosong!")
            return
        end

        local TpRemote = RS:FindFirstChild("tp")

        if TpRemote then
            print("Mencoba Warp ke: " .. targetWorld)
            if WindUI then WindUI:Notify({ Title = "Warping", Content = "Warp langsung ke: " .. targetWorld, Icon = "plane" }) end
            pcall(function() TpRemote:FireServer(targetWorld) end)
        else
            print("Lagi di World! Menyiapkan Auto-Warp untuk di Lobby...")
            if WindUI then WindUI:Notify({ Title = "Auto-Warp", Content = "Keluar world... Auto-warp disiapkan!", Icon = "loader" }) end
            
            if queue_on_tp then
                local autoWarpScript = string.format([[
                    task.spawn(function()
                        local target = "%s"
                        local RS = game:GetService("ReplicatedStorage")
                        local tpRemote = RS:WaitForChild("tp", 15)
                        
                        if tpRemote then
                            task.wait(0.5) 
                            tpRemote:FireServer(target)
                        end
                    end)
                ]], targetWorld)
                queue_on_tp(autoWarpScript)
            end

            local exitRemote = RS:WaitForChild("Remotes"):FindFirstChild("RequestPlayerExitWorld")
            if exitRemote then pcall(function() exitRemote:InvokeServer() end) end
        end
    end)
end

-- ==========================================
-- UI: WORLD SELECTION & TELEPORT (ADVANCED)
-- ==========================================
Tab:Divider({ Title = "🌍 Teleport / Warp World" })

Tab:Input({
    Title = "Nama World",
    Flag = "TargetWarp_ConfigFlag", 
    Placeholder = "Contoh: buy, world2...",
    Value = getgenv().TargetWarpWorld,
    Callback = function(value)
        getgenv().TargetWarpWorld = value
    end
})

Tab:Toggle({
    Title = "Izinkan Auto-Warp saat Script Jalan",
    Desc = "Centang ini jika ingin otomatis warp saat pindah server/dieksekusi",
    Flag = "EnableAutoWarp_ConfigFlag",
    Value = getgenv().EnableAutoWarp,
    Callback = function(value)
        getgenv().EnableAutoWarp = value
    end
})

Tab:Space()

Tab:Button({
    Title = "🚀 Warp Sekarang! (Manual)",
    Callback = function()
        ExecuteWarp()
    end
})

Tab:Button({
    Title = "🛑 Batalkan Auto-Warp",
    Desc = "Pencet ini cepat-cepat kalau scriptnya lagi ngitung mundur mau warp!",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        getgenv().CancelWarp = true
        if WindUI then
            WindUI:Notify({
                Title = "DIBATALKAN",
                Content = "Auto-warp berhasil dihentikan!",
                Icon = "x-circle",
            })
        end
    end
})

-- ==========================================
-- UI: CONFIG MANAGEMENT
-- ==========================================
Tab:Divider({ Title = "⚙️ Config Management" })

local ConfigNameInput = Tab:Input({
    Title = "Config Name",
    Placeholder = "Ketik nama config...",
    Value = ConfigName,
    Callback = function(value) ConfigName = value end
})

local AllConfigsDropdown = Tab:Dropdown({
    Title = "Available Configs",
    Values = ConfigManager:AllConfigs(),
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value
        ConfigNameInput:Set(value)
    end
})

Tab:Button({
    Title = "Save / Create Config",
    Icon = "save",
    Callback = function()
        Window.CurrentConfig = ConfigManager:Config(ConfigName)
        if Window.CurrentConfig:Save() then
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
            if WindUI then WindUI:Notify({ Title = "Config Saved", Content = "Tersimpan: " .. ConfigName, Icon = "check" }) end
        end
    end
})

Tab:Button({
    Title = "Load Config",
    Icon = "folder-open",
    Callback = function()
        Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
        Window.CurrentConfig:Load()
    end
})

Tab:Button({
    Title = "Delete Config",
    Icon = "trash",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        local configPath = "WindUI/KzoyzHub/config/" .. ConfigName .. ".json"
        if isfile and isfile(configPath) and delfile then
            delfile(configPath)
            ConfigName = "Default"
            ConfigNameInput:Set("Default")
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
        end
    end
})

-- ==========================================
-- UI: AUTO-EXECUTE SETTINGS
-- ==========================================
Tab:Divider({ Title = "🚀 Auto-Execute" })

local currentAutoLoad = GetAutoLoad()
local configListForAuto = ConfigManager:AllConfigs()
table.insert(configListForAuto, 1, "None") 

_G.AutoLoadDropdown = Tab:Dropdown({
    Title = "Set Auto-Load Config",
    Values = configListForAuto,
    Value = currentAutoLoad,
    Callback = function(value)
        SetAutoLoad(value)
    end
})

-- ==========================================
-- EKSEKUSI AUTO-LOAD SAAT SCRIPT JALAN
-- ==========================================
task.spawn(function()
    task.wait(1.5) 
    local autoConfig = GetAutoLoad()
    
    if autoConfig ~= "None" then
        local checkPath = "WindUI/KzoyzHub/config/" .. autoConfig .. ".json"
        if isfile and isfile(checkPath) then
            Window.CurrentConfig = ConfigManager:CreateConfig(autoConfig)
            
            if Window.CurrentConfig:Load() then
                ConfigName = autoConfig
                ConfigNameInput:Set(autoConfig)
                
                task.wait(1) -- Tunggu UI nyesuain value
                
                -- CEK APAKAH TOGGLE AUTO-WARP DICENTANG
                if getgenv().EnableAutoWarp then
                    getgenv().CancelWarp = false -- Reset status batal
                    
                    if WindUI then
                        WindUI:Notify({
                            Title = "AWAS!",
                            Content = "Auto-Warp akan jalan dalam 5 DETIK! Pencet 'Batalkan' jika ingin stop.",
                            Icon = "alert-triangle",
                            Duration = 5
                        })
                    end
                    
                    -- Hitung mundur 5 detik, cek terus kalau tombol Batal dipencet
                    for i = 5, 1, -1 do
                        if getgenv().CancelWarp then break end
                        task.wait(1)
                    end
                    
                    -- Kalau setelah 5 detik nggak dibatalin, sikat!
                    if not getgenv().CancelWarp then
                        ExecuteWarp()
                    end
                else
                    print("Auto-Load selesai, tapi Auto-Warp mati. Menunggu perintah manual.")
                end
            end
        end
    end
end)
