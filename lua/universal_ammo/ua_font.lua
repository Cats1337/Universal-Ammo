UniversalAmmo = UniversalAmmo or {}
UniversalAmmo._FontCache = UniversalAmmo._FontCache or {}

local ValidFonts = {
    ["ChatFont"] = true,
    ["CreditsText"] = true,
    ["DermaDefault"] = true,
    ["DermaLarge"] = true,
    ["HudDefault"] = true,
    ["Trebuchet18"] = true
}

function UniversalAmmo.GetDynamicFont(size, fontName)
    size = math.Clamp(math.floor(size or 30), 6, 200)
    fontName = ValidFonts[fontName] and fontName or "DermaDefault"

    local key = fontName .. "_" .. size

    if UniversalAmmo._FontCache[key] then
        return UniversalAmmo._FontCache[key]
    end

    local outName = "UA_DYN_" .. key

    surface.CreateFont(outName, {
        font = fontName,
        size = size,
        weight = 800,
        antialias = true,
        shadow = false
    })

    UniversalAmmo._FontCache[key] = outName
    return outName
end