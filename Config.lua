local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index!") return end

-- ==========================================
-- SETUP VARIABLES & SERVICES
-- ==========================================
local RS = game:GetService("ReplicatedStorage")
local queue_on_tp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or getgenv().queue_on_teleport

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"

-- Set default world jika belum ada
getgenv().TargetWarpWorld = getgenv().TargetWarpWorld or "buy"

-- ==========================================
-- SISTEM AUTO-LOAD (MEMBACA FILE)
-- ==========================================
local autoLoadPath = "WindUI/KzoyzHub/AutoLoad.txt"

local function GetAutoLoad()
    if isfile and isfile(autoLoadPath) and readfile then
        local saved = readfile(autoLoadPath)
        if saved and saved ~= "" then
            return saved
        end
    end
    return "None"
end

local function SetAutoLoad(name)
    if writefile then
        writefile(autoLoadPath, name)
    end
end

-- ==========================================
-- FUNGSI UTAMA UNTUK WARP (Biar bisa dipanggil otomatis)
-- ==========================================
local function ExecuteWarp()
    task.spawn(function()
        local targetWorld = getgenv().TargetWarpWorld
        if not targetWorld or targetWorld == "" then
            if WindUI then WindUI:Notify({ Title = "Error", Content = "Nama World masih kosong!", Icon = "x" }) end
            warn("Nama World masih kosong!")
            return
        end

        local TpRemote = RS:FindFirstChild("tp")

        if TpRemote then
            -- Kondisi 1: Sedang di Lobby
            print("Mencoba Warp ke: " .. targetWorld)
            if WindUI then WindUI:Notify({ Title = "Warping", Content = "Warp langsung ke: " .. targetWorld, Icon = "plane" }) end
            pcall(function() TpRemote:FireServer(targetWorld) end)
        else
            -- Kondisi 2: Sedang di World
            print("Lagi di World! Menyiapkan Auto-Warp untuk di Lobby...")
            if WindUI then WindUI:Notify({ Title = "Auto-Warp", Content = "Keluar world... Auto-warp disiapkan!", Icon = "loader" }) end
            
            if queue_on_tp then
                local autoWarpScript = string.format([[
                    task.spawn(function()
                        local target = "%s"
                        print("Menunggu remote tp untuk auto-warp ke: " .. target)
                        local RS = game:GetService("ReplicatedStorage")
                        local tpRemote = RS:WaitForChild("tp", 15)
                        
                        if tpRemote then
                            task.wait(0.5) 
                            tpRemote:FireServer(target)
                        else
                            warn("Gagal Auto-Warp: Remote 'tp' tidak ditemukan di Lobby.")
                        end
                    end)
                ]], targetWorld)
                
                queue_on_tp(autoWarpScript)
            else
                warn("Executor kamu nggak support 'queue_on_teleport'. Script Auto-Warp terpaksa dibatalkan.")
            end

            local exitRemote = RS:WaitForChild("Remotes"):FindFirstChild("RequestPlayerExitWorld")
            if exitRemote then
                pcall(function() exitRemote:InvokeServer() end)
            end
        end
    end)
end

-- ==========================================
-- UI: WORLD SELECTION & TELEPORT (ADVANCED)
-- ==========================================
Tab:Divider({ Title = "🌍 Teleport / Warp World" })

local WorldInput = Tab:Input({
    Title = "Nama World",
    Flag = "TargetWarp_ConfigFlag", 
    Placeholder = "Contoh: buy, world2...",
    Value = getgenv().TargetWarpWorld,
    Callback = function(value)
        getgenv().TargetWarpWorld = value
    end
})

Tab:Button({
    Title = "🚀 Warp Sekarang!",
    Callback = function()
        ExecuteWarp() -- Memanggil fungsi warp saat diklik manual
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
    Callback = function(value)
        ConfigName = value
    end
})

Tab:Space()

local AllConfigsDropdown = Tab:Dropdown({
    Title = "Available Configs",
    Desc = "Pilih config yang sudah kamu simpan sebelumnya",
    Values = ConfigManager:AllConfigs(),
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value
        ConfigNameInput:Set(value)
    end
})

Tab:Space()

Tab:Button({
    Title = "Save / Create Config",
    Icon = "save",
    Callback = function()
        Window.CurrentConfig = ConfigManager:Config(ConfigName)
        if Window.CurrentConfig:Save() then
            if WindUI then
                WindUI:Notify({
                    Title = "Config Saved",
                    Content = "Berhasil menyimpan config: " .. ConfigName,
                    Icon = "check",
                })
            end
            
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
        end
    end
})

Tab:Space()

Tab:Button({
    Title = "Load Config",
    Icon = "folder-open",
    Callback = function()
        Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
        if Window.CurrentConfig:Load() then
            if WindUI then
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = "Berhasil memuat config: " .. ConfigName,
                    Icon = "refresh-cw",
                })
            end
        end
    end
})

Tab:Space()

Tab:Button({
    Title = "Delete Config",
    Icon = "trash",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        local configPath = "WindUI/KzoyzHub/config/" .. ConfigName .. ".json"
        
        if isfile and isfile(configPath) and delfile then
            delfile(configPath)
            if WindUI then
                WindUI:Notify({
                    Title = "Config Deleted",
                    Content = "Berhasil menghapus config: " .. ConfigName,
                    Icon = "trash",
                })
            end
            
            ConfigName = "Default"
            ConfigNameInput:Set("Default")
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            
            if _G.AutoLoadDropdown then
                local updatedConfigs = ConfigManager:AllConfigs()
                table.insert(updatedConfigs, 1, "None")
                _G.AutoLoadDropdown:Refresh(updatedConfigs)
            end
        else
            if WindUI then
                WindUI:Notify({
                    Title = "Error",
                    Content = "File tidak ditemukan di folder config!",
                    Icon = "x",
                })
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
    Desc = "Pilih config yang otomatis jalan saat script dieksekusi",
    Values = configListForAuto,
    Value = currentAutoLoad,
    Callback = function(value)
        SetAutoLoad(value)
        if value ~= "None" and WindUI then
            WindUI:Notify({
                Title = "Auto-Load Set",
                Content = "Config '" .. value .. "' akan diload saat script jalan.",
                Icon = "check",
            })
        end
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
            print("[KzoyzHub] Menjalankan Auto-Load Config:", autoConfig)
            Window.CurrentConfig = ConfigManager:CreateConfig(autoConfig)
            
            if Window.CurrentConfig:Load() then
                ConfigName = autoConfig
                ConfigNameInput:Set(autoConfig)
                
                if WindUI then
                    WindUI:Notify({
                        Title = "Auto-Execute",
                        Content = "Config dimuat! Memulai Auto-Warp...",
                        Icon = "rocket",
                    })
                end
                
                -- Jeda 1 detik biar memastikan value Input-nya udah beneran ke-load
                task.wait(1)
                
                -- LANGSUNG EKSEKUSI WARP SEOLAH-OLAH PENCET TOMBOL
                ExecuteWarp()
            end
        else
            warn("[KzoyzHub] Auto-load gagal: Config tidak ditemukan.")
        end
    end
end)
