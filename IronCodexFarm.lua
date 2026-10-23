-- IronCodexFarm | Airflow UI edition
-- Auto Farm source: frilshiaputri-cmd/Ironsoulkaitun V2
-- Auto Redeem source: frilshiaputri-cmd/K5 (not the V2 redeem module)
-- Built-in V2 toast announcements are disabled in this repository's bootstrap_v2.lua.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("[IronCodexFarm] LocalPlayer unavailable") end

local REPO_RAW = "https://raw.githubusercontent.com/frilshiaputri-cmd/IronCodexFarm/main/"
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/joustingmatch/-3/refs/heads/main/Source.luau"))()
getgenv().__Airflow = Airflow

local Window = Airflow:CreateWindow({
    Name = "IronCodexFarm",
    LoadingSubtitle = "Airflow UI • IronSoul V2 + K5 Redeem",
    Icon = "rbxassetid://106988550042558",
    ToggleUIKeybind = "RightShift",
    Backdrop = {Weather = "None", Tint = 0.45},
    AdaptiveSize = false,
    UIScale = 1,
    Density = "Default",
    Size = UDim2.fromOffset(700, 430),
    ConfigurationSaving = {Enabled = false, FolderName = "IronCodexFarm"},
})

local MainTab = Window:CreateTab({Name = "Main", Icon = "house"})
local FarmTab = Window:CreateTab({Name = "Auto Farm", Icon = "tree-pine"})
local RedeemTab = Window:CreateTab({Name = "Redeem", Icon = "gift"})
local SettingsTab = Window:CreateTab({Name = "Settings", Icon = "settings"})

local MainPanel = MainTab:CreateGroupbox({Name = "Status", Side = "Left"})
local MainInfo = MainTab:CreateGroupbox({Name = "Information", Side = "Right"})
local FarmPanel = FarmTab:CreateGroupbox({Name = "Farm Controls", Side = "Left"})
local RedeemPanel = RedeemTab:CreateGroupbox({Name = "K5 Auto Redeem", Side = "Left"})
local RedeemStatsPanel = RedeemTab:CreateGroupbox({Name = "Redeem Statistics", Side = "Right"})
local SafetyPanel = SettingsTab:CreateGroupbox({Name = "Independent Controls", Side = "Left"})

MainPanel:CreateLabel("IronCodexFarm loaded • press RightShift to hide/show")
MainInfo:CreateParagraph({
    Title = "Source separation",
    Content = "Auto Farm uses the Kaitun V2 bootstrap. Auto Redeem uses K5 codes. Toggles are independent; enabling Redeem does not start Farm.",
})

local function notify(title, message)
    pcall(function()
        Window:Notify({Title = title, Content = message, Duration = 4})
    end)
end

local Config = getgenv().IronSoulConfig
if type(Config) ~= "table" then Config = {} end
-- FPS Booster/FPS cap disabled.
local isTeleportRestore = getgenv().IronCodexFarmTeleportContinuation == true
if not isTeleportRestore then
    Config.FARM = "OFF"
end
Config.TICKETS = Config.TICKETS or "SMART"
Config.HEADLESS = Config.HEADLESS ~= false
Config.DEBUG_LOGS = Config.DEBUG_LOGS == true
Config.LEVEL_STOP = 40 -- stop Auto Farm at level 40 and return to lobby
Config.AUTO_REDEEM = false
Config.ANTI_AFK = Config.ANTI_AFK == true
Config.AutoSkill = Config.AutoSkill ~= false
getgenv().IronSoulConfig = Config
if not isTeleportRestore then
    getgenv().IronSoulMasterEnabled = false
    getgenv().IronSoulStopRequested = true
else
    getgenv().IronSoulMasterEnabled = Config.FARM ~= "OFF"
    getgenv().IronSoulStopRequested = Config.FARM == "OFF"
end
-- Clear stale level-stop flags only on a fresh/manual session; preserve them during teleport restore.
if not isTeleportRestore then
    getgenv().IronSoulLevelStopReached = false
    getgenv().IronSoulLevelStopLevel = nil
end

local farmBootstrapped = isTeleportRestore
local farmEnabled = isTeleportRestore and Config.FARM ~= "OFF"
local function setFarm(enabled)
    enabled = enabled == true
    if enabled == farmEnabled then return end
    farmEnabled = enabled

    if enabled then
        Config.FARM = getgenv().IronSoulPreviousFarmMode or "NEWBIE"
        getgenv().IronSoulStopRequested = false
        getgenv().IronSoulMasterEnabled = true
        if not farmBootstrapped then
            local ok, err = pcall(function()
                local source = game:HttpGet(REPO_RAW .. "bootstrap_v2.lua")
                assert(type(source) == "string" and #source > 0, "bootstrap_v2.lua kosong")
                local fn, compileErr = loadstring(source)
                assert(fn, compileErr or "Gagal compile bootstrap V2")
                fn()
            end)
            if ok then
                farmBootstrapped = true
                notify("Auto Farm", "Kaitun V2 dijalankan.")
            else
                farmEnabled = false
                Config.FARM = "OFF"
                getgenv().IronSoulMasterEnabled = false
                getgenv().IronSoulStopRequested = true
                warn("[IronCodexFarm] Auto Farm gagal: " .. tostring(err))
                notify("Auto Farm gagal", tostring(err))
            end
        else
            if type(getgenv().IronSoulSetMasterEnabled) == "function" then
                pcall(getgenv().IronSoulSetMasterEnabled, true)
            end
            notify("Auto Farm", "Diaktifkan.")
        end
    else
        if Config.FARM ~= "OFF" then
            getgenv().IronSoulPreviousFarmMode = Config.FARM
        end
        Config.FARM = "OFF"
        getgenv().IronSoulStopRequested = true
        getgenv().IronSoulMasterEnabled = false
        if type(getgenv().IronSoulSetMasterEnabled) == "function" then
            pcall(getgenv().IronSoulSetMasterEnabled, false)
        end
        notify("Auto Farm", "Dimatikan.")
    end
end

-- Bootstrap can call this when level 40 is reached to switch the UI toggle off.
getgenv().IronCodexFarmSetFarm = function(enabled)
    setFarm(enabled == true)
end

FarmPanel:CreateToggle({
    Name = "Auto Farm (IronSoul V2)",
    Flag = "ICF_AUTO_FARM",
    Default = farmEnabled,
    Callback = function(value)
        setFarm(value)
    end,
})

FarmPanel:CreateToggle({
    Name = "Auto Skill",
    Flag = "ICF_AUTO_SKILL",
    Default = Config.AutoSkill,
    Callback = function(value)
        Config.AutoSkill = value == true
        getgenv().IronSoulConfig = Config
    end,
})

-- Codes copied from the user's K5 repository K5_HUB_REDEEM_UPDATED.txt.
local Codes = {
    "runekify", "Dray28", "RIKUSOULS", "Ahjughh", "T3nsei", "Ghifa", "Sukunay",
    "MERGIXS", "SIGURIH", "CA2", "Lulzsec", "druscxlla", "MAHAFEY", "LALAGANG",
    "Luthador2121", "AAM", "ToadPlaysGamesTTV", "Uzi", "TT_Mentally_ill_K.N",
    "luknojo", "Zeny", "Maple", "Fujiesane", "VeeruChan", "HELOS", "LezoCr",
    "ARES", "Laplace", "Deco", "dasher", "Nyxaria", "ProfGab", "SUB2BLAZESTARS",
    "Nothing", "Dism", "FannTzy", "Darkfeniks", "Sneptuno", "SUPER MBUD", "Marcell",
    "Markbhatra", "DrekathSenpai", "smiley", "Sine", "GT_HANNI", "Erijero",
    "DanoNano", "WettySNK", "obe", "Dekday", "Qyuu", "Gwynne", "PapiJoy",
    "Taalonely", "Darren", "MADUNN", "Clipz7112", "omjiwa", "PaPaX", "Ryu",
    "DEI_Yumeko", "Chrisss", "Gryffin", "ARKANGHEL", "tony_vt", "Ryokenn",
    "ReyPomuchi", "Freca", "Shan", "Bebek", "Les", "SEYUnever", "Izumi_Senpai",
    "Staysmoovey", "NisardHelpOnlyWoman", "Kiota2", "LZZ_019BEST", "PepCalcot",
    "Astral", "Lifauzi", "Shirooo0312_IRONSOUL", "Ewaa", "FRanime_OFFICIEL",
    "WerNate", "Ascart", "Sweetiee24", "Monarch", "Aetherix", "SUB2MULTIST789",
    "RENZEI100", "Skywinter86", "Heso", "Ghelayyy", "Heartguard", "ZARGAKSTONE",
    "RaykorBR", "EJ(YURU)", "Rujika", "Giovanni_GG", "GRAYWOLF", "SUB_TO_ITS_HUNTER",
    "Alex._.SINN", "AbuelaCalcot", "ChakGIM", "Zhien", "SamudraSelatan", "qzq",
    "BaraWell", "Horrortoki", "Vinxies", "minamee", "IRONSOULWEEKEND27",
    "S4ENDLESSTOWER", "TRADEISLANDUPDATE", "North", "NEXCU", "EvLCrys",
    "Joy_Blox", "DEYMMM", "DD_Noir", "Maple_13xNoir"
}
local REDEEM_DELAY = 16.1
local redeemEnabled = false
local redeemRunning = false
local redeemedCount = 0
local statusLabel = RedeemPanel:CreateLabel("Status: Idle")
local statsLabel = RedeemStatsPanel:CreateLabel("Total codes: " .. #Codes .. "\nRequests sent: 0")
local function updateRedeemStats()
    local text = ("Total codes: %d | Requests sent: %d"):format(#Codes, redeemedCount)
    pcall(function()
        if statsLabel and statsLabel.SetText then statsLabel:SetText(text) end
    end)
    print("[IronCodexFarm Redeem Stats] " .. text)
end
updateRedeemStats()

local function setRedeemStatus(message)
    pcall(function()
        if statusLabel and statusLabel.SetText then statusLabel:SetText("Status: " .. message) end
    end)
    print("[IronCodexFarm Redeem] " .. message)
end

local function redeemOne(code)
    local framework = ReplicatedStorage:FindFirstChild("Framework")
    local systems = framework and framework:FindFirstChild("Systems")
    local codesSystem = systems and systems:FindFirstChild("CodesSystem")
    local remote = codesSystem and codesSystem:FindFirstChild("CodeRE")
    if not remote or not remote:IsA("RemoteEvent") then
        return false, "CodeRE tidak ditemukan"
    end
    local ok, err = pcall(function()
        remote:FireServer({event = "usecode", code = code})
    end)
    return ok, err
end

local function startRedeem()
    if redeemRunning then return end
    redeemRunning = true
    task.spawn(function()
        for index, code in ipairs(Codes) do
            if not redeemEnabled then break end
            setRedeemStatus(("Memproses %d/%d: %s"):format(index, #Codes, code))
            local ok, err = redeemOne(code)
            if ok then
                redeemedCount += 1
                updateRedeemStats()
            else
                warn("[IronCodexFarm Redeem] " .. tostring(err))
            end
            if index < #Codes and redeemEnabled then task.wait(REDEEM_DELAY) end
        end
        setRedeemStatus(redeemEnabled and ("Selesai • request berhasil: " .. redeemedCount) or "Dihentikan")
        redeemRunning = false
    end)
end

RedeemPanel:CreateToggle({
    Name = "Auto Redeem (K5)",
    Flag = "ICF_AUTO_REDEEM",
    Default = false,
    Callback = function(value)
        redeemEnabled = value == true
        Config.AUTO_REDEEM = redeemEnabled
        -- This callback intentionally does not call setFarm or change IronSoulMasterEnabled.
        if redeemEnabled then
            setRedeemStatus("Memulai • " .. #Codes .. " kode")
            startRedeem()
        else
            setRedeemStatus("OFF")
        end
    end,
})

RedeemPanel:CreateButton({
    Name = "Reset Redeem Counter",
    Callback = function()
        redeemedCount = 0
        updateRedeemStats()
        setRedeemStatus("Counter direset")
    end,
})

local antiAfkConnection
local antiAfkEnabled = false
local function setAntiAfk(enabled)
    antiAfkEnabled = enabled == true
    Config.ANTI_AFK = antiAfkEnabled
    if antiAfkConnection then
        pcall(function() antiAfkConnection:Disconnect() end)
        antiAfkConnection = nil
    end
    if antiAfkEnabled then
        local ok, connection = pcall(function()
            return LocalPlayer.Idled:Connect(function()
                if not antiAfkEnabled then return end
                pcall(function()
                    local virtualUser = game:GetService("VirtualUser")
                    virtualUser:CaptureController()
                    virtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end)
        if ok then antiAfkConnection = connection end
    end
    notify("Anti AFK", antiAfkEnabled and "Diaktifkan." or "Dimatikan.")
end

SafetyPanel:CreateToggle({
    Name = "Anti AFK",
    Flag = "ICF_ANTI_AFK",
    Default = false,
    Callback = function(value)
        setAntiAfk(value)
    end,
})

SafetyPanel:CreateLabel("V2 announcements are disabled in this repository bootstrap.")
SafetyPanel:CreateLabel("FPS Booster removed. Auto Farm and Auto Redeem have independent toggles.")
SafetyPanel:CreateLabel("Redeem delay: 16.1 seconds per code (K5 source setting).")

Window:Notify({Title = "IronCodexFarm", Content = "Airflow UI loaded.", Duration = 3})
print("[IronCodexFarm] Airflow UI loaded")
