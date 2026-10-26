-- IronCodexFarm | Airflow UI edition
-- Auto Farm: IronSoul V2 bootstrap (separate controller)
-- Auto Redeem: K5 code list
-- Season Spin + Claim All: standalone IronCodexFarm reward controller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("[IronCodexFarm] LocalPlayer unavailable") end

local REPO_RAW = "https://raw.githubusercontent.com/frilshiaputri-cmd/IronCodexFarm/main/"
-- Use the original Airflow UI library and its documented API.
-- Upstream: https://github.com/PookiePepelsss/Airflow-UI
local AIRFLOW_URL = "https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"
local airflowSource = game:HttpGet(AIRFLOW_URL)
assert(type(airflowSource) == "string" and #airflowSource > 0, "[IronCodexFarm] Airflow source is empty")
local airflowLoader, airflowCompileError = loadstring(airflowSource)
assert(airflowLoader, airflowCompileError or "[IronCodexFarm] Airflow failed to compile")
local Airflow = airflowLoader()
getgenv().__Airflow = Airflow

local Window = Airflow:CreateWindow({
    Name = "K5-HUB",
    LoadingSubtitle = "IronCodexFarm • Auto Farm / Redeem / Rewards",
    Icon = "rbxassetid://106988550042558",
    Theme = "Midnight",
    ToggleUIKeybind = "RightShift",
    Size = UDim2.fromOffset(700, 520),
    MinSize = Vector2.new(320, 360),
    KeepOnScreen = true,
    OpenButton = {Title = "K5-HUB", Icon = "wind"},
    Loading = {Enabled = true, Title = "K5-HUB", Text = "Preparing Airflow UI", Duration = 1.2},
    ConfigurationSaving = {Enabled = false, FolderName = "IronCodexFarm"},
})

local MainTab = Window:CreateTab({Name = "Main", Icon = "layout-dashboard"})
local FarmTab = Window:CreateTab({Name = "Auto Farm", Icon = "trees"})
local RedeemTab = Window:CreateTab({Name = "Redeem", Icon = "gift"})
local SettingsTab = Window:CreateTab({Name = "Settings", Icon = "settings"})

-- Aliases keep the existing feature logic intact while using Airflow's native tab API.
local MainPanel = MainTab
local MainInfo = MainTab
local FarmPanel = FarmTab
local RedeemPanel = RedeemTab
local RedeemStatsPanel = RedeemTab
local SafetyPanel = SettingsTab

MainPanel:CreateLabel("K5-HUB loaded • press RightShift to hide/show")
MainInfo:CreateParagraph({
    Title = "Source separation",
    Content = "Auto Farm uses its own toggle. K5 Redeem and the standalone Season Spin / Claim All controller run independently; reward toggles do not start Auto Farm.",
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
getgenv().IronCodexFarmTeleportContinuation = nil
if not isTeleportRestore then
    Config.FARM = "OFF"
end
Config.TICKETS = Config.TICKETS or "SMART"
Config.HEADLESS = Config.HEADLESS ~= false
Config.DEBUG_LOGS = Config.DEBUG_LOGS == true
Config.LEVEL_STOP = 40 -- stop Auto Farm at level 40 and return to lobby
Config.AUTO_REDEEM = false
local RewardConfig = getgenv().IronCodexFarmRewardConfig
if type(RewardConfig) ~= "table" then RewardConfig = {} end
RewardConfig.AUTO_SEASON_SPIN = RewardConfig.AUTO_SEASON_SPIN == true
RewardConfig.AUTO_CLAIM_ALL = RewardConfig.AUTO_CLAIM_ALL == true
getgenv().IronCodexFarmRewardConfig = RewardConfig
Config.ANTI_AFK = Config.ANTI_AFK == true
Config.AutoSkill = Config.AutoSkill ~= false
Config.AutoSwitchWeapon = false -- IronCodexFarm: disable automatic weapon switching
getgenv().IronSoulConfig = Config

-- Standalone reward automation owned by IronCodexFarm; it does not load V2.
local RewardAutomation
do
    local ok, result = pcall(function()
        local source = game:HttpGet(REPO_RAW .. "systems/reward_automation.lua")
        assert(type(source) == "string" and #source > 0, "reward_automation.lua kosong")
        local fn, compileErr = loadstring(source)
        assert(fn, compileErr or "Gagal compile reward_automation.lua")
        return fn()
    end)
    if ok and type(result) == "table" then
        RewardAutomation = result
    else
        warn("[IronCodexFarm] Reward automation gagal dimuat: " .. tostring(result))
    end
end

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
    if enabled == farmEnabled then
        -- On teleport restore, the V2 bootstrap may have started before the UI.
        -- Re-assert the master state once the UI is ready instead of returning early.
        if enabled then
            Config.FARM = Config.FARM ~= "OFF" and Config.FARM or (getgenv().IronSoulPreviousFarmMode or "NEWBIE")
            getgenv().IronSoulStopRequested = false
            getgenv().IronSoulMasterEnabled = true
            if type(getgenv().IronSoulSetMasterEnabled) == "function" then
                pcall(getgenv().IronSoulSetMasterEnabled, true)
            end
        end
        return
    end
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
    CurrentValue = farmEnabled,
    Callback = function(value)
        setFarm(value)
    end,
})

FarmPanel:CreateToggle({
    Name = "Auto Skill (IronSoul V2)",
    Flag = "ICF_AUTO_SKILL",
    CurrentValue = Config.AutoSkill,
    Callback = function(value)
        Config.AutoSkill = value == true
        getgenv().IronSoulConfig = Config
    end,
})

-- K5 Auto Redeem integration: code list synced from K5_HUB_REDEEM_UPDATED.txt.
local Codes = {
    "runekify",
    "Dray28",
    "RIKUSOULS",
    "Ahjughh",
    "T3nsei",
    "Ghifa",
    "Sukunay",
    "MERGIXS",
    "SIGURIH",
    "CA2",
    "Lulzsec",
    "druscxlla",
    "MAHAFEY",
    "LALAGANG",
    "Luthador2121",
    "AAM",
    "ToadPlaysGamesTTV",
    "Uzi",
    "TT_Mentally_ill_K.N",
    "luknojo",
    "Zeny",
    "Maple",
    "Fujiesane",
    "VeeruChan",
    "HELOS",
    "LezoCr",
    "ARES",
    "Laplace",
    "Deco",
    "dasher",
    "Nyxaria",
    "ProfGab",
    "SUB2BLAZESTARS",
    "Nothing",
    "Dism",
    "FannTzy",
    "Darkfeniks",
    "Sneptuno",
    "SUPER MBUD",
    "Marcell",
    "Markbhatra",
    "DrekathSenpai",
    "smiley",
    "Sine",
    "GT_HANNI",
    "Erijero",
    "DanoNano",
    "WettySNK",
    "obe",
    "Dekday",
    "Qyuu",
    "Gwynne",
    "PapiJoy",
    "Taalonely",
    "Darren",
    "MADUNN",
    "Clipz7112",
    "omjiwa",
    "PaPaX",
    "Ryu",
    "DEI_Yumeko",
    "Chrisss",
    "Gryffin",
    "ARKANGHEL",
    "tony_vt",
    "Ryokenn",
    "ReyPomuchi",
    "Freca",
    "Shan",
    "Bebek",
    "Les",
    "SEYUnever",
    "Izumi_Senpai",
    "Staysmoovey",
    "NisardHelpOnlyWoman",
    "Kiota2",
    "LZZ_019BEST",
    "PepCalcot",
    "Astral",
    "Lifauzi",
    "Shirooo0312_IRONSOUL",
    "Ewaa",
    "FRanime_OFFICIEL",
    "WerNate",
    "Ascart",
    "Sweetiee24",
    "Monarch",
    "Aetherix",
    "SUB2MULTIST789",
    "RENZEI100",
    "Skywinter86",
    "Heso",
    "Ghelayyy",
    "Heartguard",
    "ZARGAKSTONE",
    "RaykorBR",
    "EJ(YURU)",
    "Rujika",
    "Giovanni_GG",
    "GRAYWOLF",
    "SUB_TO_ITS_HUNTER",
    "Alex._.SINN",
    "AbuelaCalcot",
    "ChakGIM",
    "Zhien",
    "LacilBlueBerry",
    "SamudraSelatan",
    "qzq",
    "BaraWell",
    "Horrortoki",
    "Vinxies",
    "minamee",
    "IRONSOULWEEKEND27",
    "S4ENDLESSTOWER",
    "TRADEISLANDUPDATE",
    "North",
    "NEXCU",
    "EvLCrys",
    "Joy_Blox",
    "DEYMMM",
    "DD_Noir",
    "Maple_13xNoir",
    "IRONSOULWEEKEND28",
    "BOWANDSKILLTREE",
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
        if statsLabel and statsLabel.Set then statsLabel:Set(text) end
    end)
    print("[IronCodexFarm Redeem Stats] " .. text)
end
updateRedeemStats()

local function setRedeemStatus(message)
    pcall(function()
        if statusLabel and statusLabel.Set then statusLabel:Set("Status: " .. message) end
    end)
    print("[IronCodexFarm Redeem] " .. message)
end

local function redeemOne(code)
    -- Sama seperti alur K5: tunggu remote siap, maksimum 90 detik.
    local deadline = os.clock() + 90
    local remote
    repeat
        local framework = ReplicatedStorage:FindFirstChild("Framework")
        local systems = framework and framework:FindFirstChild("Systems")
        local codesSystem = systems and systems:FindFirstChild("CodesSystem")
        remote = codesSystem and codesSystem:FindFirstChild("CodeRE")
        if remote and remote:IsA("RemoteEvent") then break end
        if not redeemEnabled then return false, "Auto Redeem dihentikan" end
        task.wait(1)
    until os.clock() >= deadline
    if not remote or not remote:IsA("RemoteEvent") then
        return false, "CodeRE tidak ditemukan setelah menunggu 90 detik"
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
    CurrentValue = false,
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

RedeemPanel:CreateToggle({
    Name = "Auto Spin Season Tickets (IronCodexFarm)",
    Flag = "ICF_AUTO_SEASON_SPIN",
    CurrentValue = RewardConfig.AUTO_SEASON_SPIN == true,
    Callback = function(value)
        RewardConfig.AUTO_SEASON_SPIN = value == true
        getgenv().IronCodexFarmRewardConfig = RewardConfig
        if RewardAutomation then
            RewardAutomation:SetSpin(value)
            notify("Season Ticket Spin", value and "ON • sistem mandiri IronCodexFarm aktif." or "OFF • spin otomatis dihentikan.")
        else
            notify("Season Ticket Spin", "Sistem gagal dimuat; periksa console.")
        end
    end,
})

RedeemPanel:CreateToggle({
    Name = "Auto Claim All (IronCodexFarm)",
    Flag = "ICF_AUTO_CLAIM_ALL",
    CurrentValue = RewardConfig.AUTO_CLAIM_ALL == true,
    Callback = function(value)
        RewardConfig.AUTO_CLAIM_ALL = value == true
        getgenv().IronCodexFarmRewardConfig = RewardConfig
        if RewardAutomation then
            RewardAutomation:SetClaimAll(value)
            notify("Auto Claim All", value and "ON • sistem mandiri berjalan di Lobby pada Level 40+." or "OFF • klaim tambahan dinonaktifkan.")
        else
            notify("Auto Claim All", "Sistem gagal dimuat; periksa console.")
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

-- Anti-AFK adapted from the AntiAfk module in Anime Dice.lua.txt
-- Source behavior: one Idled connection; the toggle controls whether its callback acts.
local VirtualUser = game:GetService("VirtualUser")
local antiAfkEnabled = false
local antiAfkConnection

local function onAntiAfkIdled()
    if not antiAfkEnabled then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end

local function setAntiAfk(enabled)
    antiAfkEnabled = enabled == true
    Config.ANTI_AFK = antiAfkEnabled

    if not antiAfkConnection then
        local ok, connection = pcall(function()
            return LocalPlayer.Idled:Connect(onAntiAfkIdled)
        end)
        if ok then
            antiAfkConnection = connection
        else
            warn("[IronCodexFarm] Anti-AFK connection failed:", connection)
        end
    end

    notify("Anti AFK", antiAfkEnabled and "Diaktifkan." or "Dimatikan.")
end

SafetyPanel:CreateToggle({
    Name = "Anti AFK",
    Flag = "ICF_ANTI_AFK",
    CurrentValue = false,
    Callback = function(value)
        setAntiAfk(value)
    end,
})

SafetyPanel:CreateLabel("V2 announcements are disabled in this repository bootstrap.")
SafetyPanel:CreateLabel("FPS Booster and automatic weapon switching are disabled.")
SafetyPanel:CreateLabel("Auto Farm OFF pauses IronSoul V2 combat; ON resumes it.")
SafetyPanel:CreateLabel("Auto Skill controls the farm skill system; reward automation is standalone.")
SafetyPanel:CreateLabel("Auto Farm and Auto Redeem have independent toggles.")
SafetyPanel:CreateLabel("K5 Redeem: 124 codes • 16.1s delay • waits up to 90s for CodeRE.")

-- Set this only after all tabs, panels, and controls have been created.
getgenv().IronCodexFarmUILoaded = true
Window:Notify({Title = "K5-HUB", Content = "Original Airflow UI loaded.", Duration = 3})
print("[IronCodexFarm] Airflow UI loaded")

-- On a queued map/Place teleport, wait until the Airflow table exists before
-- re-asserting Auto Farm. Fresh/manual starts still require the user toggle.
if isTeleportRestore then
    task.defer(function()
        task.wait(0.5)
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui and Window then
            setFarm(true)
            notify("Auto Farm", "UI selesai dimuat; melanjutkan Auto Farm.")
        end
    end)
end
