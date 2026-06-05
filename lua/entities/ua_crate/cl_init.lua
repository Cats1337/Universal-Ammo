include("shared.lua")

net.Receive("UA_BroadcastConfig", function()
    local json = net.ReadString()
    local tbl = UniversalAmmo.DeserializeConfig(json)
    if not istable(tbl) then return end

    UniversalAmmo.Config = tbl

    if SwitchRef then
        SwitchRef(activeTab, true)
    end
end)

-- Helper functions
local function LerpColor(t, c1, c2)
    return Color(
        Lerp(t, c1.r, c2.r),
        Lerp(t, c1.g, c2.g),
        Lerp(t, c1.b, c2.b)
    )
end

local function GetHpColor(hp, maxHp)
    if maxHp <= 0 then
        return Color(255, 255, 255)
    end

    local pct = math.Clamp(hp / maxHp, 0, 1)

    local white  = Color(255, 255, 255)
    local yellow = Color(255, 255,   0)
    local orange = Color(255, 165,   0)
    local red    = Color(255,   0,   0)

    if pct >= 0.75 then
        return LerpColor((pct - 0.75) / 0.25, yellow, white)
    elseif pct >= 0.50 then
        return LerpColor((pct - 0.50) / 0.25, orange, yellow)
    elseif pct >= 0.25 then
        return LerpColor((pct - 0.25) / 0.25, red, orange)
    else
        return red
    end
end

function ENT:Draw()
    self:DrawModel()

    local cfgRoot = UniversalAmmo.Config
    if not cfgRoot then return end

    local cfg = cfgRoot.crate
    local labelSettings = cfgRoot.labelSettings.crate
    if not cfg or not labelSettings then return end

    local Pos = self:GetPos()
    local Ang = self:GetAngles()

    Ang:RotateAroundAxis(Ang:Right(), 270)
    Ang:RotateAroundAxis(Ang:Up(), 90)

    local hp = self:Health()
    local maxHp = cfg.maxHealth or 100
    local hpClr = math.Clamp(hp * 2.5, 0, 255)

    cam.Start3D2D(Pos + Ang:Up() * 17, Ang, 0.18)

        local lineSpacing = 30
        local startY = -110

        for lineNum = 1, 4 do
            local lineKey = "line" .. lineNum
            local lineCfg = labelSettings[lineKey]

            if lineCfg then
                local yOffset = startY + (lineNum - 1) * lineSpacing
                local text = lineCfg.text or ""

                local fontSize = math.Clamp(lineCfg.size or 30, 8, 120)
                local font = UniversalAmmo.GetDynamicFont(
                    fontSize,
                    lineCfg.font or "DermaDefault"
                )

                -- HP LINE
                local isHealthLine = (labelSettings.healthLine == lineNum)

                if isHealthLine then
                    if maxHp > 1 then
                        local text = hp .. " / " .. maxHp .. " HP"

                        if lineCfg.dropShadow then
                            draw.SimpleText(
                                text,
                                font,
                                1,
                                yOffset + 1,
                                Color(0, 0, 0),
                                TEXT_ALIGN_CENTER,
                                TEXT_ALIGN_CENTER
                            )
                        end

                        draw.SimpleText(
                            text,
                            font,
                            0,
                            yOffset,
                            GetHpColor(hp, maxHp),
                            TEXT_ALIGN_CENTER,
                            TEXT_ALIGN_CENTER
                        )
                    end

                elseif text ~= "" then
                    local clr = lineCfg.color or { r = 255, g = 255, b = 255 }

                    if lineCfg.dropShadow then
                        draw.SimpleText(text, font, 1, yOffset + 1, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    draw.SimpleText(
                        text,
                        font,
                        0,
                        yOffset,
                        Color(clr.r, clr.g, clr.b),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end
        end

    cam.End3D2D()
end