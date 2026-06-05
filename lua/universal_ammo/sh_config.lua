-- ============================================================
--  Universal Ammo - Shared Config (UPDATED SAFE VERSION)
-- ============================================================

UniversalAmmo = UniversalAmmo or {}

-- ------------------------------------------------------------
-- DEFAULT CONFIG
-- ------------------------------------------------------------
UniversalAmmo.DefaultConfig = {

    box = {
        enabled    = true,
        model      = "models/items/boxmrounds.mdl",
        maxHealth  = 1,
        multiplier = 2,
        amountMin  = 1,
        amountMax  = 80,
        cooldown   = 1.0,
    },

    crate = {
        enabled    = true,
        model      = "models/items/item_item_crate.mdl",
        maxHealth  = 100,
        multiplier = 10,
        amountMin  = 10,
        amountMax  = 30,
        cooldown   = 0.5,
    },

    vend = {
        enabled    = true,
        model      = "models/props_interiors/VendingMachineSoda01a.mdl",
        maxHealth  = 0,
        multiplier = 10,
        amountMin  = 10,
        amountMax  = 30,
        cooldown   = 0.13,
    },

    labelSettings = {

        box = {
            position = {
                height = 5.65,
                scale = 0.10,
                startY = -80,
                spacing = 30
            },

            healthLine = 4,
            healthShowMax = true,

            line1 = {
                text = "",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line2 = {
                text = "Universal",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line3 = {
                text = "Ammo",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line4 = {
                text = "HP",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            }
        },

        crate = {
            position = {
                height = 8,
                scale = 0.10,
                startY = -110,
                spacing = 30
            },

            healthLine = 4,
            healthShowMax = true,

            line1 = {
                text = "Infinite",
                size = 30,
                font = "DermaDefault",
                color = { r = 150, g = 150, b = 150 },
                dropShadow = true
            },

            line2 = {
                text = "Universal",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line3 = {
                text = "Ammo",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line4 = {
                text = "HP",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            }
        },

        vend = {
            position = {
                height = 18,
                scale = 0.10,
                startY = -110,
                spacing = 30
            },

            healthLine = 4,
            healthShowMax = true,

            line1 = {
                text = "",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line2 = {
                text = "",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line3 = {
                text = "",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            },

            line4 = {
                text = "HP",
                size = 30,
                font = "DermaDefault",
                color = { r = 255, g = 255, b = 255 },
                dropShadow = true
            }
        }
    },

    general = {
        enabled = true,
        items = {
            { addon = "fas2_ifak", name = "Hemostats", value = 0 },
            { addon = "fas2_ifak", name = "Bandages", value = 0 },
            { addon = "fas2_ifak", name = "Quikclots", value = 0 },
        }
    },

    ammoOverrides = {
        pistol = 30,
        smg1 = 45,
        ar2 = 60,
        buckshot = 8,
        grenades = 3,
    },

    listMode = "blacklist",

    listItems = {
        "m9k_davy_crockett",
    },

    adminGroup = "superadmin",
}

-- ------------------------------------------------------------
-- Runtime config
-- ------------------------------------------------------------
UniversalAmmo.Config = table.Copy(UniversalAmmo.DefaultConfig)

-- ------------------------------------------------------------
-- Deep merge helper (critical for partial saves)
-- ------------------------------------------------------------
function UniversalAmmo.DeepMerge(base, patch)
    if type(base) ~= "table" then return patch end
    if type(patch) ~= "table" then return base end

    local out = table.Copy(base)

    for k, v in pairs(patch) do
        if type(v) == "table" and type(out[k]) == "table" then
            out[k] = UniversalAmmo.DeepMerge(out[k], v)
        else
            out[k] = v
        end
    end

    return out
end

-- ------------------------------------------------------------
-- Serialization helpers (fixes your override/list issues)
-- ------------------------------------------------------------
function UniversalAmmo.SerializeConfig(cfg)
    return util.TableToJSON(cfg or {}, true)
end

function UniversalAmmo.DeserializeConfig(str)
    local tbl = util.JSONToTable(str or "")
    if not tbl then return table.Copy(UniversalAmmo.DefaultConfig) end
    return UniversalAmmo.DeepMerge(UniversalAmmo.DefaultConfig, tbl)
end

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
function UniversalAmmo.GetColor(tbl)
    return Color(tbl.r, tbl.g, tbl.b)
end

function UniversalAmmo.IsAllowed(weaponClass)
    local cfg = UniversalAmmo.Config
    if cfg.listMode == "none" then return true end

    local inList = false
    for _, v in ipairs(cfg.listItems or {}) do
        if v == weaponClass then inList = true break end
    end

    if cfg.listMode == "blacklist" then return not inList end
    if cfg.listMode == "whitelist" then return inList end
    return true
end

function UniversalAmmo.GetAmmoAmount(ammoName, weapon, entityType)
    local overrides = UniversalAmmo.Config.ammoOverrides or {}
    if overrides[ammoName] then
        return overrides[ammoName]
    end

    local ec = UniversalAmmo.Config[entityType]
    return math.Clamp(
        weapon:GetMaxClip1() * ec.multiplier,
        ec.amountMin,
        ec.amountMax
    )
end