--========================================================--
-- K5-Hub V2 - COMPACT MOBILE BOOT WITH DIAGNOSTICS
--========================================================--

getgenv().IronSoulConfig =
    getgenv().IronSoulConfig
    or {
        FPS_CAP = 60,
        FARM = "NEWBIE",
        TICKETS = "SMART",
        HEADLESS = true,
        AutoSkill = true,
    }

local Config = getgenv().IronSoulConfig
-- Preserve the level-stop state while a queued teleport continuation is booting.
if getgenv().IronCodexFarmTeleportContinuation ~= true then
    getgenv().IronSoulLevelStopReached = false
    getgenv().IronSoulLevelStopLevel = nil
end
if type(Config) == "table" then Config.LEVEL_STOP = 40 end
local VERSION = "K5_HUB_V2_AUTOEXEC_RETRY_20261021_3"
local BASE =
    "https://raw.githubusercontent.com/"
    .. "frilshiaputri-cmd/Ironsoulkaitun/main/"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local DIAG_FILE = "K5Hub_V2_Diagnostics.txt"
local DIAG_MAX_CHARS = 12000
local diagLines = {}
local function diag(level, message)
    local line = string.format(
        "[%s] [%s] place=%s user=%s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(level),
        tostring(game.PlaceId),
        LocalPlayer and tostring(LocalPlayer.Name) or "?",
        tostring(message)
    )
    table.insert(diagLines, line)
    while #diagLines > 80 do table.remove(diagLines, 1) end
    print("[K5-Hub V2 Diagnostics] " .. line)
    if type(writefile) == "function" then
        pcall(function()
            local old = ""
            if type(readfile) == "function" and type(isfile) == "function" and isfile(DIAG_FILE) then
                old = readfile(DIAG_FILE) or ""
            end
            local combined = old .. (old ~= "" and "\\n" or "") .. line
            if #combined > DIAG_MAX_CHARS then
                combined = string.sub(combined, #combined - DIAG_MAX_CHARS + 1)
            end
            writefile(DIAG_FILE, combined)
        end)
    end
end
getgenv().K5HubDiagnostics = {
    Log = function(message) diag("INFO", message) end,
    Error = function(message) diag("ERROR", message) end,
    File = DIAG_FILE,
}
diag("INFO", "bootstrap entry started; version=K5-Hub V2")

local TUTORIAL_PLACE_ID = 76701861705540
local LOBBY_PLACE_ID = 117533937949084

local LEVEL_STOP = 40
local levelStopTriggered = false

local function readPlayerLevel()
    local level = tonumber(LocalPlayer and LocalPlayer:GetAttribute("LG_Level"))
    if level then return level end
    local replicatedStorage = game:GetService("ReplicatedStorage")
    for _, obj in ipairs(replicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "DataUtil" then
            local ok, util = pcall(require, obj)
            if ok and type(util) == "table" and type(util.GetPlayerData) == "function" then
                local okData, data = pcall(function()
                    return util:GetPlayerData(LocalPlayer)
                end)
                if okData and type(data) == "table" and type(data.LevelData) == "table" then
                    level = tonumber(data.LevelData.Level)
                    if level then return level end
                end
            end
        end
    end
    return nil
end

local function enforceLevelStop(level)
    if levelStopTriggered or not level or level < LEVEL_STOP then return end
    levelStopTriggered = true
    local env = getgenv()
    env.IronSoulLevelStopReached = true
    env.IronSoulLevelStopLevel = level
    env.IronSoulStopRequested = true
    env.IronSoulMasterEnabled = false
    if type(env.IronSoulConfig) == "table" then
        env.IronSoulConfig.LEVEL_STOP = LEVEL_STOP
        env.IronSoulConfig.FARM = "OFF"
    end
    diag("WARN", "LEVEL CAP reached Lv" .. tostring(level) .. "/" .. tostring(LEVEL_STOP) .. "; Auto Farm OFF; returning to lobby without kick")
    if type(env.IronSoulStatus) == "function" then
        pcall(env.IronSoulStatus, "LEVEL CAP | Lv" .. tostring(level) .. "/40 | Auto Farm OFF | returning to lobby")
    end

    if type(env.IronCodexFarmSetFarm) == "function" then
        pcall(env.IronCodexFarmSetFarm, false, "level-cap")
    end

    local isLobby = game.PlaceId == LOBBY_PLACE_ID or workspace:GetAttribute("WorldName") == "Lobby"
    if not isLobby and LocalPlayer and LocalPlayer.Parent then
        task.spawn(function()
            task.wait(0.5)
            local ok, err = pcall(function()
                game:GetService("TeleportService"):Teleport(LOBBY_PLACE_ID, LocalPlayer)
            end)
            if not ok then
                diag("ERROR", "Level-cap lobby teleport failed: " .. tostring(err))
                if type(env.IronSoulStatus) == "function" then
                    pcall(env.IronSoulStatus, "LEVEL CAP | teleport ke lobby gagal; Auto Farm tetap OFF")
                end
            end
        end)
    end
end

task.spawn(function()
    while LocalPlayer and LocalPlayer.Parent and not levelStopTriggered do
        local level = readPlayerLevel()
        if level and level >= LEVEL_STOP then
            enforceLevelStop(level)
            break
        end
        task.wait(1)
    end
end)

-- IronCodexFarm: stop Auto Farm at level 40; return to lobby without kicking.
-- Prevent duplicate queued copies in the same server/job.
do
    local key = tostring(game.PlaceId) .. "|" .. tostring(game.JobId)
    local old = getgenv().IronSoulBootstrapGuard
    if type(old) == "table"
        and old.Key == key
        and os.clock() - tonumber(old.At or 0) < 5
    then
        return
    end
    getgenv().IronSoulBootstrapGuard = { Key = key, At = os.clock() }
end

-- FPS cap modification removed as requested.
local function executorName()
    if type(identifyexecutor) == "function" then
        local ok, a, b = pcall(identifyexecutor)
        if ok then return tostring(a or b or "Unknown") end
    end
    if type(getexecutorname) == "function" then
        local ok, value = pcall(getexecutorname)
        if ok then return tostring(value or "Unknown") end
    end
    return "Unknown"
end

local function findRealTeleportQueue()
    local env = getgenv()
    local candidates = {
        {"queue_on_teleport", env.queue_on_teleport},
        {"queueonteleport", env.queueonteleport},
        {"queue_on_tp", env.queue_on_tp},
        {"queueontp", env.queueontp},
    }
    if type(syn) == "table" then
        table.insert(candidates, {"syn.queue_on_teleport", syn.queue_on_teleport})
    end
    if type(fluxus) == "table" then
        table.insert(candidates, {"fluxus.queue_on_teleport", fluxus.queue_on_teleport})
    end
    for _, row in ipairs(candidates) do
        if type(row[2]) == "function" then return row[2], row[1] end
    end
    return nil, "none"
end

local RealQueue, RealQueueName = findRealTeleportQueue()
local Caps = {
    Version = "K5-Hub V2",
    Executor = executorName(),
    Touch = UserInputService.TouchEnabled == true,
    Queue = type(RealQueue) == "function",
    QueueName = RealQueueName,
    WriteFile = type(writefile) == "function",
    ReadFile = type(readfile) == "function",
    MakeFolder = type(makefolder) == "function",
    FireSignal = type(firesignal) == "function",
    GetConnections = type(getconnections) == "function",
    FirePrompt = type(fireproximityprompt) == "function",
    FireTouch = type(firetouchinterest) == "function",
}
getgenv().IronSoulExecutorCaps = Caps
getgenv().IronSoulTeleportQueueAvailable = Caps.Queue
getgenv().IronSoulManualQueueMode = not Caps.Queue

-- Remove any leftover green master-toggle overlay from older V2 sessions.
task.spawn(function()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then return end
    for _, child in ipairs(pg:GetChildren()) do
        if child.Name == "K5MasterToggleGui" then
            pcall(function() child:Destroy() end)
        elseif child:IsA("ScreenGui") then
            for _, item in ipairs(child:GetDescendants()) do
                if item:IsA("TextButton") and item.Name == "MasterToggle" then
                    local txt = tostring(item.Text or "")
                    if string.find(txt, "K5%-HUB V2") then
                        pcall(function() child:Destroy() end)
                        break
                    end
                end
            end
        end
    end
end)

local stickyError = false

-- K5-Hub V2: no on-screen status table/panel. Keep diagnostics in console/file.
local function status(message)
    local value = tostring(message or "")
    local isError = string.sub(value, 1, 5) == "ERROR" or string.sub(value, 1, 5) == "STUCK"
    if isError then
        stickyError = true
    elseif stickyError and string.sub(value, 1, 5) ~= "RESET" then
        return
    end
    diag(isError and "ERROR" or "STATUS", value)

    -- IronCodexFarm: V2 on-screen toast announcements are disabled.

    if type(writefile) == "function" then
        pcall(writefile, "K5Hub_V2_Status.txt", table.concat({
            "Version=K5-Hub V2",
            "Executor=" .. tostring(Caps.Executor),
            "Touch=" .. tostring(Caps.Touch),
            "NativeQueue=" .. tostring(Caps.Queue),
            "QueueName=" .. tostring(Caps.QueueName),
            "ManualQueueMode=" .. tostring(not Caps.Queue),
            "WriteFile=" .. tostring(Caps.WriteFile),
            "ReadFile=" .. tostring(Caps.ReadFile),
            "FireSignal=" .. tostring(Caps.FireSignal),
            "GetConnections=" .. tostring(Caps.GetConnections),
            "FirePrompt=" .. tostring(Caps.FirePrompt),
            "FireTouch=" .. tostring(Caps.FireTouch),
            "PlaceId=" .. tostring(game.PlaceId),
            "Status=" .. value,
        }, "\\n"))
    end
end
getgenv().IronSoulStatus = status

-- Master switch UI removed: keep V2 enabled without the extra green overlay.
-- The panel logo is used only to collapse/expand the status panel.
local function setMasterEnabled(value)
    local env = getgenv()
    env.IronSoulMasterEnabled = value == true
    local cfg = env.IronSoulConfig
    if type(cfg) == "table" and value == true and cfg.FARM == "OFF" then
        cfg.FARM = env.IronSoulPreviousFarmMode or "NEWBIE"
        env.IronSoulPreviousFarmMode = nil
    end
    env.IronSoulStopRequested = value ~= true
    local perf = env.K5PerformanceBooster
    if type(perf) == "table" and type(perf.SetEnabled) == "function" then
        pcall(perf.SetEnabled, value == true)
    end
end
getgenv().IronSoulSetMasterEnabled = setMasterEnabled
getgenv().IronSoulMasterEnabled = true
getgenv().IronSoulManagedConnections = getgenv().IronSoulManagedConnections or {}
getgenv().IronSoulManagedThreads = getgenv().IronSoulManagedThreads or {}

-- V2 Anti-AFK: react to Roblox's idle signal without running a constant jump loop.
-- This can reduce idle-disconnect risk, but cannot prevent server-side kicks,
-- network loss, maintenance, or experience-specific AFK rules.
if Config.ANTI_AFK ~= false and LocalPlayer then
    local antiAfkConnected = false
    local function handleIdle()
        local ok, VirtualUser = pcall(function()
            return game:GetService("VirtualUser")
        end)
        local inputWorked = false
        if ok and VirtualUser then
            inputWorked = pcall(function()
                local camera = workspace.CurrentCamera
                VirtualUser:CaptureController()
                VirtualUser:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
                task.wait(0.8)
                VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
            end)
        end
        if not inputWorked then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                pcall(function()
                    humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
        end
        diag("INFO", "Anti-AFK idle signal handled")
    end
    local ok, connection = pcall(function()
        return LocalPlayer.Idled:Connect(handleIdle)
    end)
    antiAfkConnected = ok and connection ~= nil
    getgenv().IronSoulAntiAfkStatus = antiAfkConnected and "connected" or "unavailable"
    diag("INFO", "Anti-AFK status=" .. tostring(getgenv().IronSoulAntiAfkStatus))
end

task.spawn(function()
    while LocalPlayer and LocalPlayer.Parent do
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        diag("DATA", string.format(
            "heartbeat version=K5-Hub V2 level=%s health=%s/%s world=%s queue=%s",
            tostring(LocalPlayer:GetAttribute("LG_Level") or "n/a"),
            tostring(humanoid and humanoid.Health or "n/a"),
            tostring(humanoid and humanoid.MaxHealth or "n/a"),
            tostring(workspace:GetAttribute("WorldName") or "n/a"),
            tostring(Caps.Queue)
        ))
        task.wait(30)
    end
end)

status("Boot | " .. tostring(Caps.Executor) .. " | nativeQueue=" .. tostring(Caps.Queue))

local function compatibilityQueue(payload)
    payload = tostring(payload or "")
    if type(RealQueue) == "function" then
        local ok, err = pcall(RealQueue, payload)
        if ok then return true end
        status("ERROR | native teleport queue failed | " .. tostring(err))
        return false
    end
    getgenv().IronSoulManualQueuedPayload = payload
    if type(writefile) == "function" then
        pcall(writefile, "IronSoul_Reexecute_AfterTeleport_V2.lua", payload)
    end
    status("Native teleport queue unavailable | manual re-execution required")
    return false
end
pcall(function() rawset(getgenv(), "queue_on_teleport", compatibilityQueue) end)

local fetchCounter = 0
local function cacheBust(path)
    fetchCounter += 1
    -- Keep Auto Farm on Kaitun V2's own modules and patch chain.
    return BASE .. path .. "?isv=" .. VERSION .. "&n=" .. tostring(fetchCounter) .. "&t=" .. tostring(os.time())
end

local function normalizeSource(source)
    if type(source) ~= "string" then return nil, "source is not a string" end
    if string.sub(source, 1, 3) == "\239\187\191" then source = string.sub(source, 4) end
    local b1, b2 = string.byte(source, 1), string.byte(source, 2)
    if (b1 == 255 and b2 == 254) or (b1 == 254 and b2 == 255) then return nil, "UTF-16 source received" end
    local prefixes = {"\226\128\139", "\226\128\140", "\226\128\141", "\226\129\160"}
    local changed = true
    while changed do
        changed = false
        for _, prefix in ipairs(prefixes) do
            if string.sub(source, 1, #prefix) == prefix then
                source = string.sub(source, #prefix + 1)
                changed = true
            end
        end
    end
    return source
end

local function stripLevelCapGuard(source, path)
    if path == "systems/combat.lua" or path == "systems/lobby.lua" then
        -- Keep Kaitun V2 level-cap guards intact.
    elseif path == "systems/lobby_base_v60_1.lua" then
        -- Always use normal queue/progression flow; remove the old Lv40-only lobby branch.
        local first = string.find(source, "-- At the level cap, allow Daily Quest-only maintenance", 1, true)
        local last = string.find(source, "local JOURNAL_FILE =", first or 1, true)
        if first and last and last > first then
            local replacement = [[local queue = queue_on_teleport or (syn and syn.queue_on_teleport)
if type(queue) ~= "function" then
    return stop("V2 requires queue_on_teleport to continue dungeon progression.")
end
local queueBootstrap = getgenv().IronSoulQueueBootstrap
if type(queueBootstrap) ~= "function" then
    return stop("V2 bootstrap queue helper missing.")
end

]]
            source = string.sub(source, 1, first - 1) .. replacement .. string.sub(source, last)
        end
        first = string.find(source, "-- V2 reward policy: ONLY claim Daily Quest.", 1, true)
        last = string.find(source, "local dailyLoginPending,", first or 1, true)
        if first and last and last > first then
            source = string.sub(source, 1, first - 1)
                .. "-- IronCodexFarm: Lv40-only reward gate disabled.\n\n"
                .. string.sub(source, last)
        end
        first = string.find(source, "-- Kick only after all Lv40 reward-claim functions above have been attempted.", 1, true)
        last = string.find(source, "-- AUTO SEASON SPIN DISABLED:", first or 1, true)
        if first and last and last > first then
            source = string.sub(source, 1, first - 1)
                .. "-- IronCodexFarm: level-based kick disabled.\n\n"
                .. string.sub(source, last)
        end
    end
    return source
end

local function shortError(err)
    local value = tostring(err or "unknown")
    if #value > 190 then value = string.sub(value, 1, 190) .. "..." end
    return value
end

local function loadRaw(path)
    if getgenv().IronSoulMasterEnabled == false then
        status("MASTER OFF | module blocked: " .. tostring(path))
        return false, "K5-HUB master switch is OFF"
    end
    status("Loading | " .. tostring(path))
    local ok, source = pcall(game.HttpGet, game, cacheBust(path))
    if not ok or type(source) ~= "string" then
        local message = "HTTP load failed | " .. tostring(path) .. " | " .. tostring(source)
        diag("ERROR", message); warn("[K5-Hub V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local normalized, normalizeErr = normalizeSource(source)
    if not normalized then
        local message = "Source normalization failed | " .. tostring(path) .. " | " .. tostring(normalizeErr)
        warn("[K5-Hub V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    normalized = stripLevelCapGuard(normalized, path)
    local fn, err = loadstring(normalized)
    if not fn then
        local message = "Compile failed | " .. tostring(path) .. " | " .. tostring(err)
        local lineNumber = tonumber(string.match(tostring(err), ":(%d+):"))
        if lineNumber then
            local sourceLines = string.split(normalized, "\n")
            local first = math.max(1, lineNumber - 2)
            local last = math.min(#sourceLines, lineNumber + 2)
            local context = {}
            for lineIndex = first, last do
                table.insert(context, tostring(lineIndex) .. ": " .. tostring(sourceLines[lineIndex]))
            end
            message ..= " | context: " .. table.concat(context, " || ")
        end
        warn("[K5-Hub V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    local runOk, result = pcall(fn)
    if not runOk then
        local message = "Runtime failed | " .. tostring(path) .. " | " .. tostring(result)
        warn("[K5-Hub V2] " .. message); status("ERROR | " .. shortError(message))
        return false
    end
    return true, result
end

-- MANUAL START, SESSION CONTINUATION:
-- This function is called only when an already-running, manually started
-- session deliberately schedules a cross-place transition. It does not run
-- the loader on initial join or merely because a map was opened.
local function queueBootstrap(reason)
    if getgenv().IronSoulMasterEnabled == false then
        status("MASTER OFF | teleport continuation not queued")
        return false
    end
    -- Use the original executor queue captured before installing the
    -- compatibility wrapper. Re-detecting here could find our own wrapper
    -- and recursively queue itself instead of calling Delta's native API.
    local queueFn, queueName = RealQueue, RealQueueName
    if type(queueFn) ~= "function" then
        getgenv().IronSoulManualExecutionOnly = true
        status("Teleport continuation unavailable | no native queue API detected; run LOADER_V2.lua after teleport")
        return false
    end

    local config = getgenv().IronSoulConfig or {}
    local payload = string.format([[
local config = {
    FARM = %q,
    TICKETS = %q,
    HEADLESS = %s,
    DEBUG_LOGS = %s,
    LEVEL_STOP = %s,
    AutoSkill = %s,
}
getgenv().IronSoulConfig = config

-- Teleport queues can run before the destination place finishes loading.
-- Load the full Airflow table first; Auto Farm must not start before this succeeds.
getgenv().IronCodexFarmTeleportContinuation = true
getgenv().IronCodexFarmUILoaded = false
local uiLoaded = false
local uiLastError
for uiAttempt = 1, 4 do
    task.wait(uiAttempt == 1 and 2 or 1.5)
    local uiUrl = "https://raw.githubusercontent.com/frilshiaputri-cmd/IronCodexFarm/main/IronCodexFarm.lua?v=" .. tostring(os.time()) .. "&attempt=" .. tostring(uiAttempt)
    local uiFetchOk, uiSource = pcall(function()
        return game:HttpGet(uiUrl)
    end)
    if uiFetchOk and type(uiSource) == "string" and #uiSource > 0 then
        local uiFn, uiCompileErr = loadstring(uiSource)
        if uiFn then
            local uiRunOk, uiRunErr = pcall(uiFn)
            if uiRunOk and getgenv().IronCodexFarmUILoaded == true then
                uiLoaded = true
                break
            end
            uiLastError = uiRunErr or "UI did not signal completed load"
        else
            uiLastError = uiCompileErr
        end
    else
        uiLastError = uiSource or "empty UI response"
    end
end
if not uiLoaded then
    warn("[IronCodexFarm] UI failed to load; Auto Farm remains OFF: " .. tostring(uiLastError))
    pcall(function()
        if type(writefile) == "function" then
            writefile("IronCodexFarm_UI_Load_Error.txt", tostring(uiLastError))
        end
    end)
    return
end
-- The UI consumes this marker during its own initialization; restore it so the
-- V2 bootstrap preserves teleport-continuation state (including level-stop flags).
getgenv().IronCodexFarmTeleportContinuation = true
local lastError
for attempt = 1, 4 do
    task.wait(attempt == 1 and 2 or 1.5)
    local okFetch, source = pcall(function()
        return game:HttpGet(%q .. "?v=" .. %q .. "&attempt=" .. tostring(attempt) .. "&t=" .. tostring(os.time()))
    end)
    if okFetch and type(source) == "string" and #source > 1000 then
        local fn, compileErr = loadstring(source)
        if fn then
            local okRun, runErr = pcall(fn)
            if okRun then
                -- UI was successfully loaded before bootstrap; safe to continue.
                return
            end
            lastError = runErr
        else
            lastError = compileErr
        end
    else
        lastError = source or "empty bootstrap response"
    end
end
warn("[K5-Hub V2] teleport auto-execute failed after 4 attempts: " .. tostring(lastError))
pcall(function()
    if type(writefile) == "function" then
        writefile("K5Hub_V2_AutoExecute_Error.txt", tostring(lastError))
    end
end)
]],
        tostring(config.FARM or "NEWBIE"),
        tostring(config.TICKETS or "SMART"),
        tostring(config.HEADLESS ~= false),
        tostring(config.DEBUG_LOGS == true),
        tostring(tonumber(config.LEVEL_STOP) or 0),
        tostring(config.AutoSkill ~= false),
        "https://raw.githubusercontent.com/frilshiaputri-cmd/IronCodexFarm/main/bootstrap_v2.lua",
        VERSION
    )

    local ok, err = pcall(queueFn, payload)
    if not ok or err == false then
        status("ERROR | teleport continuation queue failed via " .. tostring(queueName) .. " | " .. tostring(err))
        return false
    end

    getgenv().IronSoulManualExecutionOnly = false
    status("Teleport continuation queued via " .. tostring(queueName) .. " | " .. tostring(reason or "cross-place transition"))
    return true
end
-- Redirect legacy lobby queue requests to the V2 continuation payload.
-- The native executor queue was captured before this compatibility alias, so
-- this wrapper cannot recursively call itself or accidentally queue V1.
local function v2QueueCompatibility(_legacyPayload)
    if getgenv().IronSoulMasterEnabled == false then
        status("MASTER OFF | legacy teleport queue blocked")
        return false
    end
    return queueBootstrap("legacy lobby queue redirected to V2")
end

pcall(function()
    rawset(getgenv(), "queue_on_teleport", v2QueueCompatibility)
end)

getgenv().IronSoulBaseURL = BASE
getgenv().IronSoulQueueBootstrap = queueBootstrap
getgenv().IronSoulLoadRaw = loadRaw

-- Automatically queue the V2 bootstrap + Airflow table before a map/Place
-- teleport when Auto Farm is active. The queued payload retries loading both.
local autoTeleportQueueArmed = true
if LocalPlayer then
    pcall(function()
        LocalPlayer.OnTeleport:Connect(function(state)
            if not autoTeleportQueueArmed then return end
            if state == Enum.TeleportState.Started then
                autoTeleportQueueArmed = false
                queueBootstrap("automatic map/Place change")
            end
        end)
    end)
end

-- No automatic pre-queue: a fresh server join must never auto-execute the loader.
-- Continuation is only allowed when explicitly requested by an active session,
-- and remains governed by the normal manual-session continuation rules.

-- Performance Booster module intentionally not loaded in IronCodexFarm.
-- Intentionally do not queue on startup; run LOADER_V2.lua manually each session/map.

local function looksLikeDungeon()
    local rs = game:GetService("ReplicatedStorage")
    local hasRound = rs:FindFirstChild("GameRoundCfg") ~= nil
    local hasCombatWorld = workspace:FindFirstChild("RoundDoor")
        or workspace:FindFirstChild("EnemyNpc")
        or workspace:FindFirstChild("WorldEnemys")
    return hasRound and hasCombatWorld
end

local route, routeName
if game.PlaceId == TUTORIAL_PLACE_ID then
    -- Preserve the game's first-login tutorial/intro; do not run automation here.
    diag("INFO", "Tutorial place detected; automation intentionally skipped to preserve intro")
    return
elseif game.PlaceId == LOBBY_PLACE_ID or workspace:GetAttribute("WorldName") == "Lobby" then
    route, routeName = "systems/lobby.lua", "Lobby"
elseif looksLikeDungeon() then
    route, routeName = "systems/combat.lua", "Dungeon"
else
    for attempt = 1, 60 do
        task.wait(0.5)
        if game.PlaceId == TUTORIAL_PLACE_ID then
            route, routeName = "systems/tutorial.lua", "Tutorial"
            break
        elseif game.PlaceId == LOBBY_PLACE_ID or workspace:GetAttribute("WorldName") == "Lobby" then
            route, routeName = "systems/lobby.lua", "Lobby"
            break
        elseif looksLikeDungeon() then
            route, routeName = "systems/combat.lua", "Dungeon"
            break
        end
    end
    if not route then
        local message = "Unknown place after 30s | " .. tostring(game.PlaceId)
            .. " | WorldName=" .. tostring(workspace:GetAttribute("WorldName"))
        warn("[K5-Hub V2] " .. message); status(message)
        return
    end
end

getgenv().IronSoulRuntime = {
    Version = "K5-Hub V2",
    Route = route,
    PlaceId = game.PlaceId,
    StartedAt = os.clock(),
    NativeTeleportQueue = Caps.Queue,
}
print("[K5-Hub V2]", routeName)
status(routeName .. " | starting")
local routeOk = loadRaw(route)
return routeOk
