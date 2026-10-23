-- IronCodexFarm standalone reward automation
-- Own controller; does not load or call the IronSoulKaitun V2 bootstrap.
-- Uses the game's replicated reward modules/remotes directly.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local LOBBY_PLACE_ID = 117533937949084

local function findByName(root, name, className)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == name and (not className or obj.ClassName == className) then
            return obj
        end
    end
    return nil
end

local function req(name)
    local obj = findByName(ReplicatedStorage, name, "ModuleScript")
    if not obj then return nil end
    local ok, value = pcall(require, obj)
    return ok and value or nil
end

local function num(v) return tonumber(v) or 0 end
local function boolAt(t, key)
    if type(t) ~= "table" then return nil end
    if t[key] ~= nil then return t[key] end
    return t[tostring(key)]
end

local DataUtil = req("DataUtil")
local DailyQuestUtil = req("DailyQuestUtil")
local SevenDailyUtil = req("SevenDailyUtil")
local GuidebookUtil = req("GuidebookUtil")
local SeasonUtil = req("SeasonUtil")
local ResSeasonPass = req("ResSeasonPass")

local Controller = {
    SpinEnabled = false,
    ClaimEnabled = false,
    ClaimBusy = false,
    SpinBusy = false,
    Destroyed = false,
}

local function log(message)
    print("[IronCodexFarm Rewards] " .. tostring(message))
end

local function getData()
    if not DataUtil or type(DataUtil.GetPlayerData) ~= "function" then return nil end
    local ok, value = pcall(function()
        return DataUtil:GetPlayerData(LocalPlayer)
    end)
    return ok and type(value) == "table" and value or nil
end

local function waitFor(predicate, seconds)
    local deadline = os.clock() + (seconds or 3)
    repeat
        local ok, result = pcall(predicate)
        if ok and result then return true end
        task.wait(0.15)
    until os.clock() >= deadline or Controller.Destroyed
    return false
end

local function inLobby()
    return game.PlaceId == LOBBY_PLACE_ID and LocalPlayer and LocalPlayer.Parent ~= nil
end

local function level()
    local attr = tonumber(LocalPlayer:GetAttribute("LG_Level"))
    if attr then return attr end
    local data = getData()
    local ld = data and data.LevelData
    return tonumber(type(ld) == "table" and ld.Level) or tonumber(data and data.Level) or 0
end

local function claimDailyQuest()
    if not DailyQuestUtil or type(DailyQuestUtil.ClickGetReward) ~= "function" then return end
    local data = getData()
    local q = data and data.DailyQuest
    if type(q) ~= "table" then return end
    local completed = math.max(5, num(q.CompletedNum))
    for index = 1, math.min(completed, 100) do
        if not Controller.ClaimEnabled or Controller.Destroyed then return end
        local current = getData()
        local state = current and current.DailyQuest and current.DailyQuest.RewardState
        if boolAt(state, index) == false then
            pcall(function() DailyQuestUtil:ClickGetReward(LocalPlayer, index) end)
            waitFor(function()
                local fresh = getData()
                local freshState = fresh and fresh.DailyQuest and fresh.DailyQuest.RewardState
                return boolAt(freshState, index) == true
            end, 2)
            task.wait(0.15)
        end
    end
end

local function claimSeasonPass()
    if not SeasonUtil or not SeasonUtil.RemoteEvent or type(ResSeasonPass) ~= "table" then return end
    local seasonId = "Season3"
    if type(SeasonUtil.GetCurrentSeason) == "function" then
        local ok, value = pcall(function() return SeasonUtil:GetCurrentSeason() end)
        if ok and type(value) == "string" then seasonId = value end
    end
    local data = getData()
    local season = data and data.Seasons and data.Seasons[seasonId]
    local cfg = ResSeasonPass[seasonId]
    if type(season) ~= "table" or type(cfg) ~= "table" then return end
    local each = tonumber(cfg.EachEXP) or 1000
    local maxLevel = tonumber(cfg.MaxLevel) or 1
    local earned = math.min(maxLevel, math.floor(num(season.EXP) / each) + 1)
    for lv = 1, earned do
        if not Controller.ClaimEnabled or Controller.Destroyed then return end
        local key = "C" .. tostring(lv) .. "F"
        if season[key] ~= true then
            pcall(function() SeasonUtil.RemoteEvent:FireServer("Claim", lv) end)
            waitFor(function()
                local fresh = getData()
                return fresh and fresh.Seasons and fresh.Seasons[seasonId]
                    and fresh.Seasons[seasonId][key] == true
            end, 2)
            task.wait(0.15)
        end
    end
end

local function claimSevenDaily()
    if not SevenDailyUtil or type(SevenDailyUtil.CanGetDailyReward) ~= "function" then return end
    local data = getData()
    local seven = data and data.SevenDaily
    if type(seven) ~= "table" then return end
    local unlock = math.clamp(num(seven.UnlockDay), 0, 7)
    for day = 1, unlock do
        if not Controller.ClaimEnabled or Controller.Destroyed then return end
        local fresh = getData()
        local claimed = fresh and fresh.SevenDaily and fresh.SevenDaily.Claimed
        local key = "Day" .. tostring(day)
        if not (type(claimed) == "table" and (claimed[key] == true or boolAt(claimed, day) == true)) then
            pcall(function() SevenDailyUtil:CanGetDailyReward(LocalPlayer, day) end)
            waitFor(function()
                local now = getData()
                local state = now and now.SevenDaily and now.SevenDaily.Claimed
                return type(state) == "table" and (state[key] == true or boolAt(state, day) == true)
            end, 2)
            task.wait(0.15)
        end
    end
end

local function claimGuidebook()
    if not GuidebookUtil or type(GuidebookUtil.CanClaimed) ~= "function"
        or type(GuidebookUtil.GetRewards) ~= "function" then return end
    local categories = {
        "Unlock_Total", "Unlock_Sword", "Unlock_Heavy", "Unlock_Greatsword",
        "Unlock_Staff", "Unlock_Fist", "Unlock_Bow", "Unlock_Sickle",
        "Unlock_Helmet", "Unlock_Breastplate", "Unlock_Scrolls", "Unlock_Pet",
    }
    for _, category in ipairs(categories) do
        if not Controller.ClaimEnabled or Controller.Destroyed then return end
        for _ = 1, 12 do
            if not Controller.ClaimEnabled or Controller.Destroyed then return end
            local ok, can = pcall(function() return GuidebookUtil:CanClaimed(LocalPlayer, category) end)
            if not ok or can ~= true then break end
            local claimed = pcall(function() GuidebookUtil:GetRewards(LocalPlayer, category) end)
            if not claimed then break end
            task.wait(0.2)
        end
    end
end

local function runClaimCycle()
    if Controller.ClaimBusy or not Controller.ClaimEnabled then return end
    Controller.ClaimBusy = true
    task.spawn(function()
        -- Wait while the toggle remains ON until the player is in the lobby at Lv40+.
        while Controller.ClaimEnabled and not Controller.Destroyed do
            if inLobby() and level() >= 40 then break end
            log("Auto Claim All menunggu Lobby / Level 40; level saat ini " .. tostring(level()))
            task.wait(2)
        end
        if Controller.ClaimEnabled and not Controller.Destroyed then
            log("Memulai siklus klaim mandiri.")
            pcall(claimDailyQuest)
            pcall(claimSeasonPass)
            pcall(claimSevenDaily)
            pcall(claimGuidebook)
            log("Siklus klaim selesai; toggle OFF lalu ON untuk menjalankan siklus baru.")
        end
        Controller.ClaimBusy = false
    end)
end

local function spinCycle()
    if Controller.SpinBusy or not Controller.SpinEnabled then return end
    Controller.SpinBusy = true
    task.spawn(function()
        while Controller.SpinEnabled and not Controller.Destroyed do
            if inLobby() and SeasonUtil and SeasonUtil.RemoteEvent then
                local data = getData()
                local tickets = 0
                if type(data) == "table" then
                    if type(data.Currency) == "table" then tickets = num(data.Currency.SeasonTicket) end
                    if tickets == 0 then tickets = num(data.SeasonTicket) end
                end
                local count = tickets >= 3 and 3 or (tickets > 0 and 1 or 0)
                if count > 0 then
                    local before = tickets
                    local ok = pcall(function() SeasonUtil.RemoteEvent:FireServer("TrySeasonLottery", count) end)
                    if ok then
                        waitFor(function()
                            local fresh = getData()
                            local now = 0
                            if type(fresh) == "table" then
                                if type(fresh.Currency) == "table" then now = num(fresh.Currency.SeasonTicket) end
                                if now == 0 then now = num(fresh.SeasonTicket) end
                            end
                            return now < before
                        end, 4)
                    end
                    task.wait(1.5)
                else
                    task.wait(3)
                end
            else
                task.wait(2)
            end
        end
        Controller.SpinBusy = false
    end)
end

function Controller:SetSpin(enabled)
    self.SpinEnabled = enabled == true
    log("Auto Spin Season Tickets " .. (self.SpinEnabled and "ON" or "OFF"))
    if self.SpinEnabled then spinCycle() end
end

function Controller:SetClaimAll(enabled)
    local wasEnabled = self.ClaimEnabled
    self.ClaimEnabled = enabled == true
    log("Auto Claim All " .. (self.ClaimEnabled and "ON" or "OFF"))
    if self.ClaimEnabled and not wasEnabled then runClaimCycle() end
end

function Controller:Stop()
    self.Destroyed = true
    self.SpinEnabled = false
    self.ClaimEnabled = false
end

return Controller
