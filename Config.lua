local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index!") return end

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"

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
-- UI: WORLD SELECTION & TELEPORT
-- ==========================================
Tab:Divider({ Title = "🌍 Game Settings" })

-- Sistem Kamus (Mapping): KIRI = Nama di UI, KANAN = Argumen buat remote
local WorldMap = {
    ["World Shop (Buy)"] = "buy",
    ["World 2 (Contoh)"] = "world2", 
    ["World 3 (Contoh)"] = "world3"
}

local WorldList = {}
for name, arg in pairs(WorldMap) do
    table.insert(WorldList, name)
end

local SelectedWorldArg = "buy"

Tab:Dropdown({
    Title = "Select World",
    Desc = "Pilih world yang ingin dikunjungi",
    Values = WorldList,
    Value = "World Shop (Buy)",
    Callback = function(value)
        SelectedWorldArg = WorldMap[value]
    end
})

Tab:Space()

Tab:Button({
    Title = "Teleport to World",
    Icon = "map",
    Callback = function()
        if WindUI then
            WindUI:Notify({
                Title = "Teleporting",
                Content = "Mencoba keluar dari world saat ini...",
                Icon = "plane",
            })
        end
        
        -- Keluar dari world pakai pcall biar aman
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RequestPlayerExitWorld"):InvokeServer()
        end)
        
        -- Jeda supaya server sempat memproses
        task.wait(0.5) 
        
        -- Masuk ke world baru
        pcall(function()
            local args = { SelectedWorldArg }
            game:GetService("ReplicatedStorage"):WaitForChild("tp"):FireServer(unpack(args))
        end)
        
        if WindUI then
            WindUI:Notify({
                Title = "Success",
                Content = "Sedang memuat world baru!",
                Icon = "check",
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
            
            -- Refresh dropdown config & auto-load
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
        -- Path khusus Delta
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
            
            -- Reset UI
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
    task.wait(1) -- Beri waktu WindUI untuk loading elemen
    local autoConfig = GetAutoLoad()
    
    if autoConfig ~= "None" then
        local checkPath = "WindUI/KzoyzHub/config/" .. autoConfig .. ".json"
        if isfile and isfile(checkPath) then
            print("[KzoyzHub] Menjalankan Auto-Load Config:", autoConfig)
            Window.CurrentConfig = ConfigManager:CreateConfig(autoConfig)
            
            if Window.CurrentConfig:Load() then
                -- Update visual di Input
                ConfigName = autoConfig
                ConfigNameInput:Set(autoConfig)
                
                if WindUI then
                    WindUI:Notify({
                        Title = "Auto-Execute",
                        Content = "Config '" .. autoConfig .. "' otomatis dimuat!",
                        Icon = "rocket",
                    })
                end
            end
        else
            warn("[KzoyzHub] Auto-load gagal: Config tidak ditemukan di path.")
        end
    end
end)
