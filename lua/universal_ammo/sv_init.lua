-- ============================================================
--  Universal Ammo - Server Init
--  Handles: config persistence, net receive, client broadcast
-- ============================================================

AddCSLuaFile( "universal_ammo/sh_config.lua" )
AddCSLuaFile( "universal_ammo/cl_adminpanel.lua" )

include( "universal_ammo/sh_config.lua" )

util.AddNetworkString( "UA_OpenPanel" )
util.AddNetworkString( "UA_SaveConfig" )
util.AddNetworkString( "UA_BroadcastConfig" )
util.AddNetworkString( "UA_ResetConfig" )
util.AddNetworkString( "UA_ResetTab" )

local DATA_FILE = "universal_ammo_config.json"

-- ── Persistence ──────────────────────────────────────────────────

local function SaveConfig()
    local json = util.TableToJSON( UniversalAmmo.Config, true )
    file.Write( DATA_FILE, json )
end

local function LoadConfig()
    if file.Exists( DATA_FILE, "DATA" ) then
        local raw = file.Read( DATA_FILE, "DATA" )
        local loaded = util.JSONToTable( raw )
        if loaded then
            -- Merge loaded values over defaults so new keys always exist
            UniversalAmmo.Config = table.Merge( table.Copy( UniversalAmmo.DefaultConfig ), loaded )
            print( "[Universal Ammo] Config loaded from data/" .. DATA_FILE )
            return
        end
    end
    UniversalAmmo.Config = table.Copy( UniversalAmmo.DefaultConfig )
    print( "[Universal Ammo] No saved config found - using defaults." )
end

-- ── Broadcast helpers ─────────────────────────────────────────────

local function BroadcastConfig(target)
    local cfg = table.Copy(UniversalAmmo.Config)

    cfg._fppBlocked = table.Copy(UniversalAmmo.FPPBlockedCache or {})

    local json = util.TableToJSON(cfg)
    local recipients = target or player.GetAll()

    net.Start("UA_BroadcastConfig")
        net.WriteString(json)
    net.Send(recipients)
end

-- Send config to a single player when they join
hook.Add( "PlayerInitialSpawn", "UA_SendConfigOnJoin", function( ply )
    timer.Simple( 3, function()
        if IsValid( ply ) then
            BroadcastConfig( { ply } )
        end
    end)
end)

-- ── Admin check ───────────────────────────────────────────────────

local function IsAdmin( ply )
    if not IsValid( ply ) then return false end
    -- Superadmin always allowed; also respect configured group
    if ply:IsSuperAdmin() then return true end
    local group = UniversalAmmo.Config.adminGroup or "superadmin"
    -- DarkRP / ULX group check
    if ply.GetUserGroup then
        return ply:GetUserGroup() == group
    end

    return false
end

-- ── FPP Cache ───────────────────────────────────────────────────

UniversalAmmo.FPPBlockedCache = UniversalAmmo.FPPBlockedCache or {}

function UniversalAmmo.RefreshFPPCache()
    if not FPP or not FPP.BlockedModels then return false end

    local cache = {}

    for mdl, blocked in pairs(FPP.BlockedModels) do
        if isstring(mdl) and blocked then
            cache[string.lower(mdl)] = true
        end
    end

    UniversalAmmo.FPPBlockedCache = cache
    return true
end

hook.Add("InitPostEntity", "UA_FPP_WaitForLoad", function()
    local tries = 0

    timer.Create("UA_FPP_AutoBind", 1, 10, function()
        tries = tries + 1

        if UniversalAmmo.RefreshFPPCache() then
            timer.Remove("UA_FPP_AutoBind")
            return
        end

        if tries >= 10 then
            timer.Remove("UA_FPP_AutoBind")
            return
        end
    end)
end)

function UniversalAmmo.IsModelBlocked(model)
    if not isstring(model) then return false end

    model = string.lower(model)

    return UniversalAmmo.FPPBlockedCache[model] == true
end

-- ── Net receivers ─────────────────────────────────────────────────

-- Client requests to open the panel (server validates, then tells client to open)
net.Receive( "UA_OpenPanel", function( len, ply )
    if not IsAdmin( ply ) then
        ply:ChatPrint( "[Universal Ammo] You don't have permission to open the admin panel." )
        return
    end
    -- Send current config then tell the client to open the frame
    BroadcastConfig( { ply } )
    net.Start( "UA_OpenPanel" )
    net.Send( ply )
end)

-- Client sends updated config
net.Receive( "UA_SaveConfig", function( len, ply )
    if not IsAdmin( ply ) then return end

    local json = net.ReadString()
    local newCfg = util.JSONToTable( json )
    if not newCfg then
        ply:ChatPrint( "[Universal Ammo] Config save failed - invalid data." )
        return
    end

    UniversalAmmo.Config = table.Merge( table.Copy( UniversalAmmo.DefaultConfig ), newCfg )
    
    SaveConfig()
    BroadcastConfig()   -- push to all clients so entities update live
    print( "[Universal Ammo] Config saved by " .. ply:Name() )
end)

-- Client requests reset to defaults
local function ResetAllConfig()
    UniversalAmmo.Config = table.Copy(UniversalAmmo.DefaultConfig)
    SaveConfig()
    BroadcastConfig()
end

local function ResetTabConfig(tabName)
    -- local defaults = UniversalAmmo.DefaultConfig
    -- if not defaults or not defaults[tabName] then return end
    print("[UA] ResetTabConfig called with:", tabName)

    local defaults = UniversalAmmo.DefaultConfig
    if not defaults or not defaults[tabName] then
        print("[UA] Invalid tab:", tabName)
        return
    end

    UniversalAmmo.Config[tabName] = table.Copy(defaults[tabName])
    SaveConfig()
    BroadcastConfig()
end

net.Receive( "UA_ResetConfig", function(len, ply)
    if not IsAdmin( ply ) then return end
    ResetAllConfig()
    print( "[Universal Ammo] Config reset ALL to defaults by " .. ply:Name() )
end)

net.Receive("UA_ResetTab", function(len, ply)
    if not IsAdmin(ply) then return end

    local tabName = net.ReadString()
    ResetTabConfig(tabName)

    print("[Universal Ammo] Reset tab '" .. tabName .. "' by " .. ply:Name())
end)

-- ── Boot ──────────────────────────────────────────────────────────

LoadConfig()
