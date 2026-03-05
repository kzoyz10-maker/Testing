local Tab, Window, WindUI = ...
if type(Tab) ~= "table" then warn("Module harus di-load dari Kzoyz Index!") return end

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"

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
        -- Mengarah langsung ke folder config sesuai letak di Delta Workspace
        local configPath = "WindUI/KzoyzHub/config/" .. ConfigName .. ".json"
        
        print("[DEBUG Kzoyz] Mencoba menghapus file di: ", configPath)
        
        if isfile and isfile(configPath) and delfile then
            delfile(configPath)
            if WindUI then
                WindUI:Notify({
                    Title = "Config Deleted",
                    Content = "Berhasil menghapus config: " .. ConfigName,
                    Icon = "trash",
                })
            end
            
            -- Reset semua value biar rapi
            ConfigName = "Default"
            ConfigNameInput:Set("Default")
            AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            
        else
            if WindUI then
                WindUI:Notify({
                    Title = "Error",
                    Content = "File tidak ditemukan di folder config!",
                    Icon = "x",
                })
            end
            warn("[DEBUG Kzoyz] Gagal menghapus! Path yang dicari: " .. configPath)
        end
    end
})
