util.AddNetworkString("UA_SaveConfig")
util.AddNetworkString("UA_ResetConfig")
util.AddNetworkString("UA_BroadcastConfig")

local function Broadcast(cfg)
    net.Start("UA_BroadcastConfig")
        net.WriteString(UniversalAmmo.SerializeConfig(cfg))
    net.Broadcast()
end

local function SaveToDisk(cfg)
    if not file.IsDir("universal_ammo", "DATA") then
        file.CreateDir("universal_ammo")
    end

    file.Write(
        "universal_ammo/config.txt",
        UniversalAmmo.SerializeConfig(cfg)
    )
end

net.Receive("UA_SaveConfig", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local raw = net.ReadString()
    local tbl = UniversalAmmo.DeserializeConfig(raw)

    if not istable(tbl) then return end

    UniversalAmmo.Config = tbl

    SaveToDisk(tbl)
    Broadcast(tbl)
end)

net.Receive("UA_ResetConfig", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local defaults = table.Copy(UniversalAmmo.DefaultConfig)

    UniversalAmmo.Config = defaults

    SaveToDisk(defaults)
    Broadcast(defaults)
end)

hook.Add("Initialize", "UA_LoadConfig", function()
    if not file.IsDir("universal_ammo", "DATA") then
        file.CreateDir("universal_ammo")
    end

    local path = "universal_ammo/config.txt"

    if file.Exists(path, "DATA") then
        local raw = file.Read(path, "DATA")
        local cfg = UniversalAmmo.DeserializeConfig(raw)

        if istable(cfg) then
            UniversalAmmo.Config = cfg
        end
    end
end)