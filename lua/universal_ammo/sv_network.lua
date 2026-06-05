util.AddNetworkString("UA_SaveConfig")
util.AddNetworkString("UA_BroadcastConfig")
util.AddNetworkString("UA_ResetConfig")
util.AddNetworkString("UA_Notify")

local CONFIG_PATH = "universal_ammo/config.json"

local function EnsureDir()
    if not file.IsDir("universal_ammo", "DATA") then
        file.CreateDir("universal_ammo")
    end
end

local function SaveConfigToDisk(tbl)
    EnsureDir()
    file.Write(CONFIG_PATH, util.TableToJSON(tbl, true))
end

local function LoadConfigFromDisk()
    EnsureDir()

    if not file.Exists(CONFIG_PATH, "DATA") then
        return table.Copy(UniversalAmmo.DefaultConfig)
    end

    local raw = file.Read(CONFIG_PATH, "DATA")
    local tbl = util.JSONToTable(raw or "")

    if not istable(tbl) then
        return table.Copy(UniversalAmmo.DefaultConfig)
    end

    return UniversalAmmo.DeepMerge(UniversalAmmo.DefaultConfig, tbl)
end

-- initialize on server start
hook.Add("Initialize", "UA_LoadConfig", function()
    UniversalAmmo.Config = LoadConfigFromDisk()
end)

net.Receive("UA_SaveConfig", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local json = net.ReadString()
    local incoming = util.JSONToTable(json)

    if not istable(incoming) then return end

    -- merge instead of replace (this fixes missing fields)
    UniversalAmmo.Config = UniversalAmmo.DeepMerge(
        UniversalAmmo.DefaultConfig,
        incoming
    )

    SaveConfigToDisk(UniversalAmmo.Config)

    net.Start("UA_BroadcastConfig")
        net.WriteString(util.TableToJSON(UniversalAmmo.Config, true))
    net.Broadcast()
end)

net.Receive("UA_ResetConfig", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local fresh = table.Copy(UniversalAmmo.DefaultConfig)

    UniversalAmmo.Config = fresh

    if file.IsDir("universal_ammo", "DATA") == false then
        file.CreateDir("universal_ammo")
    end

    file.Write("universal_ammo/config.json", util.TableToJSON(fresh, true))

    net.Start("UA_BroadcastConfig")
        net.WriteString(util.TableToJSON(fresh, true))
    net.Broadcast()
end)

-- Notification system

function UniversalAmmo.Notify(ply, text, notifyType, duration)
    if not IsValid(ply) then return end

    net.Start("UA_Notify")
        net.WriteString(text)
        net.WriteUInt(notifyType or 3, 3)
        net.WriteFloat(duration or 5)
    net.Send(ply)
end