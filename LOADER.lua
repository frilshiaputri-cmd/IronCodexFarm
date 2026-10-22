-- IronCodexFarm Loader
local URL = "https://raw.githubusercontent.com/frilshiaputri-cmd/IronCodexFarm/main/IronCodexFarm.lua"
local ok, err = pcall(function()
    local source = game:HttpGet(URL)
    assert(type(source) == "string" and #source > 0, "IronCodexFarm.lua kosong")
    local fn, compileErr = loadstring(source)
    assert(fn, compileErr or "Gagal compile IronCodexFarm.lua")
    fn()
end)
if not ok then
    warn("[IronCodexFarm Loader] " .. tostring(err))
end
