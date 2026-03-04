getgenv().HubVersion = "v0.11" 

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- ========================================== --
-- [[ GLOBAL ANTI-AFK ]]
-- ========================================== --
if not getgenv().AntiAfkLoaded then
    getgenv().AntiAfkLoaded = true
    LP.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
-- ========================================== --

-- [[ LOAD WIND UI ]] --
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Kzoyz HUB " .. getgenv().HubVersion,
    Icon = "swords", 
    Author = "Koziz",
    Folder = "KzoyzHub", 
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
    
    -- [!] INI DIA RAHASIANYA BIAR GAK HILANG DI PC
    OpenButton = {
        Title = "Kzoyz HUB", -- Teks yang muncul pas tombol di-hover
        CornerRadius = UDim.new(1, 0), -- Bikin tombol jadi bulat
        StrokeThickness = 3,
        Enabled = true, -- Mengaktifkan tombol ngambang
        Draggable = true, -- Bisa digeser-geser di layar
        OnlyMobile = false, -- [PENTING] Set ke false biar di PC / Emulator juga muncul!
        Scale = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#FFD700"), -- Warna gradasi awal (Gold)
            Color3.fromHex("#FFA500")  -- Warna gradasi akhir (Orange)
        )
    }
})

-- Fungsi buat Bikin Tab + Langsung Auto-Load Script dari Github
local function AutoLoadTabFromGithub(TabName, IconName, DescText, LoadLink)
    local Tab = Window:Tab({
        Title = TabName,
        Icon = IconName,
        Desc = DescText
    })

    task.spawn(function()
        local success, scriptCode = pcall(function()
            return game:HttpGet(LoadLink)
        end)
        
        if success and scriptCode then
            local func, compileErr = loadstring(scriptCode)
            
            if func then
                local runSuccess, runErr = pcall(function()
                    -- [!] Lempar Tab, Window, dan WindUI biar bisa dipakai untuk sistem Notifikasi & Config
                    func(Tab, Window, WindUI) 
                end)
                
                if not runSuccess then
                    WindUI:Notify({ Title = "Error " .. TabName, Content = tostring(runErr), Duration = 5 })
                end
            else
                WindUI:Notify({ Title = "Compile Error " .. TabName, Content = tostring(compileErr), Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Gagal Memuat " .. TabName, Content = "Link GitHub tidak dapat diakses / bermasalah.", Duration = 5 })
        end
    end)
end

-- ========================================== --
-- [[ LIST TAB & AUTO LOAD MUNCUL SEMUA ]]
-- ========================================== --

AutoLoadTabFromGithub("Pabrik", "factory", "Pabrik (Factory)", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Pabrik.lua")
AutoLoadTabFromGithub("Auto Farm", "sprout", "Semi Auto Farm", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autofarm.lua")
AutoLoadTabFromGithub("Manager", "briefcase", "Farming Manager", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Manager.lua")
AutoLoadTabFromGithub("Auto PTHT", "tractor", "Plant & Harvest", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autoplant.lua")
AutoLoadTabFromGithub("Auto Clear World", "tree", "Clear All Blocks", "https://raw.githubusercontent.com/kzoyz10-maker/Testing/refs/heads/main/Autoclear.lua")
AutoLoadTabFromGithub("Growscan", "monitor", "Sedot Sampe Peot", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Autocollect.lua")

-- ========================================== --
-- [[ TAB TAMBAHAN: DISCORD & CONFIG ]]
-- ========================================== --
-- GANTI LINK DI BAWAH DENGAN LINK RAW GITHUB KAMU SENDIRI
AutoLoadTabFromGithub("Discord", "messages-square", "Join Community", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Discord.lua")
AutoLoadTabFromGithub("Configs", "settings-2", "Save / Load Settings", "https://raw.githubusercontent.com/kzoyz10-maker/Testingui/refs/heads/main/Config.lua")
