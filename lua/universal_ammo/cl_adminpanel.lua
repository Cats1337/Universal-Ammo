include("universal_ammo/sh_config.lua")

-- ============================================================
-- LIVE CONFIG SYNC
-- ============================================================

local activeTab = "Box"
local SwitchRef = nil

net.Receive("UA_BroadcastConfig", function()
    local json = net.ReadString()
    local tbl = UniversalAmmo.DeserializeConfig(json)
    if not istable(tbl) then return end

    UniversalAmmo.Config = tbl

    if SwitchRef then
        SwitchRef(activeTab, true)
    end
end)

-- ============================================================
-- CONFIG ACCESS
-- ============================================================

local function GetConfig()
    local cfg = UniversalAmmo.Config or table.Copy(UniversalAmmo.DefaultConfig)

    cfg._fppBlocked = cfg._fppBlocked or UniversalAmmo.Config and UniversalAmmo.Config._fppBlocked or {}

    return cfg
end

-- ============================================================
-- UI HELPERS
-- ============================================================

local function Row(parent, label, val, onChange, hint)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(28)
    row:DockMargin(0, 4, 0, 0)

    row.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        draw.RoundedBox(4, 0, 0, w, h, Color(65, 65, 85), false)
    end

    local l = vgui.Create("DLabel", row)
    l:SetText(label)
    l:Dock(LEFT)
    l:SetWide(140)
    l:SetFont("DermaDefault")
    l:SetTextColor(Color(200, 200, 220))
    l:DockMargin(8, 0, 0, 0)

    local e = vgui.Create("DTextEntry", row)
    e:Dock(FILL)
    e:SetText(tostring(val or ""))
    e:DockMargin(8, 4, 8, 4)

    if hint then
        e:SetTooltip(hint)
    end

    e.OnChange = function(self)
        if onChange then
            onChange(self:GetValue())
        end
    end

    return e
end

local function Description(p, t)
    local desc = vgui.Create("DPanel", p)
    desc:Dock(TOP)
    desc:DockMargin(0, 0, 0, 8)

    desc.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 65))
    end

    local label = vgui.Create("DLabel", desc)
    label:Dock(FILL)
    label:SetText(t)
    label:SetFont("DermaDefault")
    label:SetTextColor(Color(200, 200, 220))
    label:SetWrap(true)
    label:DockMargin(12, 8, 12, 8)

    desc.PerformLayout = function(self)
        local w = self:GetWide()
        if w <= 0 then return end

        label:SetWide(w - 24)
        label:InvalidateLayout(true)
        label:SizeToContentsY()

        self:SetTall(label:GetTall() + 16)
    end
end

local function Warning(p, t)
    local warn = vgui.Create("DPanel", p)
    warn:Dock(TOP)
    warn:DockMargin(0, 0, 0, 8)

    warn.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 50, 50))
    end

    local label = vgui.Create("DLabel", warn)
    label:Dock(FILL)
    label:SetText(t)
    label:SetFont("DermaDefault")
    label:SetTextColor(Color(240, 240, 255))
    label:SetWrap(true)
    label:SetAutoStretchVertical(true)
    label:DockMargin(12, 8, 12, 8)

    warn.PerformLayout = function(self)
        local w = self:GetWide()
        if w <= 0 then return end

        label:SetWide(w - 24)
        label:InvalidateLayout(true)
        label:SizeToContentsY()

        self:SetTall(label:GetTall() + 16)
    end
end

local function Header(p, t)
    local h = vgui.Create("DPanel", p)
    h:Dock(TOP)
    h:SetTall(32)
    h:DockMargin(0, 8, 0, 4)

    h.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 75, 100))
        draw.RoundedBox(4, 0, 0, w, h, Color(80, 100, 130), false)
        draw.SimpleText(t, "DermaLarge", w / 2, h / 2, Color(240, 240, 255), 1, 1)
    end
end

local function CenteredQuery(text, title, onYes, onNo)
    local frame = vgui.Create("DFrame")
    frame:SetSize(420, 180)
    frame:Center()
    frame:SetTitle(title or "")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
    end

    local label = vgui.Create("DLabel", frame)
    label:Dock(FILL)
    label:SetText(text)
    label:SetFont("DermaDefault")
    label:SetWrap(true)
    label:SetContentAlignment(5)
    label:SetTextColor(Color(240, 240, 240))
    label:DockMargin(12, 12, 12, 12)

    local buttonBar = vgui.Create("DPanel", frame)
    buttonBar:Dock(BOTTOM)
    buttonBar:SetTall(40)
    buttonBar.Paint = function() end

    local yes = vgui.Create("DButton", buttonBar)
    yes:Dock(LEFT)
    yes:SetWide(210)
    yes:SetText("Yes")
    yes.DoClick = function()
        frame:Close()
        if onYes then onYes() end
    end

    local no = vgui.Create("DButton", buttonBar)
    no:Dock(RIGHT)
    no:SetWide(210)
    no:SetText("No")
    no.DoClick = function()
        frame:Close()
        if onNo then onNo() end
    end
end

local function ListEditor(parent, title, data, onChange, nameHint, valueHint)
    Header(parent, title)

    data = data or {}

    local add = vgui.Create("DButton", parent)
    add:Dock(TOP)
    add:SetTall(28)
    add:SetText("+ Add " .. title)
    add:DockMargin(0, 4, 0, 4)
    add:SetFont("DermaDefaultBold")

    add.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(100, 150, 100) or Color(60, 100, 60)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 170, 120), false)
    end

    local container = vgui.Create("DPanel", parent)
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 0)
    container.Paint = nil

    local function rebuild()
        container:Clear()

        for i, v in ipairs(data) do
            local row = vgui.Create("DPanel", container)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 4, 0, 0)

            row.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 55))
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80), false)
            end

            local name = vgui.Create("DTextEntry", row)
            name:Dock(LEFT)
            name:SetWide(160)
            name:SetText(v.name or "")
            name:DockMargin(4, 4, 4, 4)
            if nameHint then
                name:SetTooltip(nameHint)
            end

            local val = vgui.Create("DTextEntry", row)
            val:Dock(FILL)
            val:SetText(tostring(v.value or 0))
            val:DockMargin(4, 4, 4, 4)
            if valueHint then
                val:SetTooltip(valueHint)
            end

            local del = vgui.Create("DButton", row)
            del:Dock(RIGHT)
            del:SetWide(32)
            del:SetText("✕")
            del:DockMargin(4, 4, 4, 4)
            del:SetFont("DermaDefaultBold")

            del.Paint = function(self, w, h)
                local bgColor = self:IsHovered() and Color(200, 100, 100) or Color(150, 50, 50)
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                draw.RoundedBox(4, 0, 0, w, h, Color(220, 120, 120), false)
            end

            del.DoClick = function()
                table.remove(data, i)
                rebuild()
                if onChange then onChange(data) end
            end

            name.OnChange = function(self)
                v.name = self:GetValue()
                if onChange then onChange(data) end
            end

            val.OnChange = function(self)
                v.value = tonumber(self:GetValue()) or v.value
                if onChange then onChange(data) end
            end
        end
        
        local totalHeight = #data * 32
        container:SetTall(totalHeight)
        parent:InvalidateLayout(true)
    end

    add.DoClick = function()
        table.insert(data, { name = "new", value = 0 })
        rebuild()
        if onChange then onChange(data) end
    end

    rebuild()
end

local function ListEditorMedical(parent, title, data, onChange, addonHint, nameHint)
    Header(parent, title)

    data = data or {}

    local add = vgui.Create("DButton", parent)
    add:Dock(TOP)
    add:SetTall(28)
    add:SetText("+ Add " .. title)
    add:DockMargin(0, 4, 0, 4)
    add:SetFont("DermaDefaultBold")

    add.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(100, 150, 100) or Color(60, 100, 60)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 170, 120), false)
    end

    local container = vgui.Create("DPanel", parent)
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 0)
    container.Paint = nil

    local function rebuild()
        container:Clear()

        for i, v in ipairs(data) do
            local row = vgui.Create("DPanel", container)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 4, 0, 0)

            row.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 55))
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80), false)
            end

            local addon = vgui.Create("DTextEntry", row)
            addon:Dock(LEFT)
            addon:SetWide(75)
            addon:SetText(v.addon or "")
            addon:DockMargin(4, 4, 4, 4)
            if addonHint then
                addon:SetTooltip(addonHint)
            end

            local name = vgui.Create("DTextEntry", row)
            name:Dock(LEFT)
            name:SetWide(75)
            name:SetText(v.name or "")
            name:DockMargin(4, 4, 4, 4)
            if nameHint then
                name:SetTooltip(nameHint)
            end

            local value = vgui.Create("DTextEntry", row)
            value:Dock(FILL)
            value:SetText(tostring(v.value or 0))
            value:DockMargin(4, 4, 4, 4)
            value:SetTooltip("Value or amount")

            local del = vgui.Create("DButton", row)
            del:Dock(RIGHT)
            del:SetWide(32)
            del:SetText("✕")
            del:DockMargin(4, 4, 4, 4)
            del:SetFont("DermaDefaultBold")

            del.Paint = function(self, w, h)
                local bgColor = self:IsHovered() and Color(200, 100, 100) or Color(150, 50, 50)
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                draw.RoundedBox(4, 0, 0, w, h, Color(220, 120, 120), false)
            end

            del.DoClick = function()
                table.remove(data, i)
                rebuild()
                if onChange then onChange(data) end
            end

            addon.OnChange = function(self)
                v.addon = self:GetValue()
                if onChange then onChange(data) end
            end

            name.OnChange = function(self)
                v.name = self:GetValue()
                if onChange then onChange(data) end
            end

            value.OnChange = function(self)
                v.value = tonumber(self:GetValue()) or v.value
                if onChange then onChange(data) end
            end
        end
        
        local totalHeight = #data * 32
        container:SetTall(totalHeight)
        parent:InvalidateLayout(true)
    end

    add.DoClick = function()
        table.insert(data, { addon = "addon_class", name = "Item Name", value = 0 })
        rebuild()
        if onChange then onChange(data) end
    end

    rebuild()
end

local function ListEditorWeapons(parent, title, data, onChange, nameHint)
    Header(parent, title)

    data = data or {}

    local add = vgui.Create("DButton", parent)
    add:Dock(TOP)
    add:SetTall(28)
    add:SetText("+ Add " .. title)
    add:DockMargin(0, 4, 0, 4)
    add:SetFont("DermaDefaultBold")

    add.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(100, 150, 100) or Color(60, 100, 60)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        draw.RoundedBox(4, 0, 0, w, h, Color(120, 170, 120), false)
    end

    local container = vgui.Create("DPanel", parent)
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 0)
    container.Paint = nil

    local function rebuild()
        container:Clear()

        for i, v in ipairs(data) do
            local row = vgui.Create("DPanel", container)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 4, 0, 0)

            row.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 55))
                draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 80), false)
            end

            local name = vgui.Create("DTextEntry", row)
            name:Dock(FILL)
            name:SetText(v.name or "")
            name:DockMargin(4, 4, 4, 4)
            if nameHint then
                name:SetTooltip(nameHint)
            end

            local del = vgui.Create("DButton", row)
            del:Dock(RIGHT)
            del:SetWide(32)
            del:SetText("✕")
            del:DockMargin(4, 4, 4, 4)
            del:SetFont("DermaDefaultBold")

            del.Paint = function(self, w, h)
                local bgColor = self:IsHovered() and Color(200, 100, 100) or Color(150, 50, 50)
                draw.RoundedBox(4, 0, 0, w, h, bgColor)
                draw.RoundedBox(4, 0, 0, w, h, Color(220, 120, 120), false)
            end

            del.DoClick = function()
                table.remove(data, i)
                rebuild()
                if onChange then onChange(data) end
            end

            name.OnChange = function(self)
                v.name = self:GetValue()
                if onChange then onChange(data) end
            end
        end
        
        local totalHeight = #data * 32
        container:SetTall(totalHeight)
        parent:InvalidateLayout(true)
    end

    add.DoClick = function()
        table.insert(data, { name = "weapon_" })
        rebuild()
        if onChange then onChange(data) end
    end

    rebuild()
end

-- ============================================================
-- ENTITY TAB
-- ============================================================

local function EntityTab(scroll, ec, entityName)
    Header(scroll, entityName .. " Settings")
    Description(scroll, "Configure entity appearance, cooldown, and ammo settings.")

    local model = string.lower(ec.model or "")
    local blocked =
        UniversalAmmo.Config
        and UniversalAmmo.Config._fppBlocked
        and UniversalAmmo.Config._fppBlocked[model]

    if blocked then
        Warning(scroll, "FPP blocked model: `" .. ec.model .. "`. This entity will not spawn.")
    end


    Row(scroll, "Model", ec.model, function(v) ec.model = v end, "e.g., models/items/boxmrounds.mdl")

    Row(scroll, "Cooldown", ec.cooldown, function(v)
        ec.cooldown = tonumber(v) or ec.cooldown
    end, "Seconds between pickups")

    Row(scroll, "Multiplier", ec.multiplier, function(v)
        ec.multiplier = tonumber(v) or ec.multiplier
    end, "Ammo multiplier (e.g., 2)")

    Row(scroll, "Min Ammo", ec.amountMin, function(v)
        ec.amountMin = tonumber(v) or ec.amountMin
    end, "Minimum ammo amount")

    Row(scroll, "Max Ammo", ec.amountMax, function(v)
        ec.amountMax = tonumber(v) or ec.amountMax
    end, "Maximum ammo amount")

    Row(scroll, "Max Health", ec.maxHealth, function(v)
        ec.maxHealth = tonumber(v) or ec.maxHealth
    end, "Leave blank for unbreakable")
end

-- ============================================================
-- BUILD ENTITY TAB CONTENT
-- ============================================================

local function EntityLabel(scroll, cfg, ent, entDisplay)
    Header(scroll, entDisplay .. " Label Settings")
    Description(scroll, "Customize the appearance of " .. entDisplay .. " labels including text, font, color, and drop shadow for each line.")

    local entCfg = cfg.labelSettings[ent]
    local LINE_COUNT = 4

    entCfg = entCfg or {}
    cfg.labelSettings[ent] = entCfg

    entCfg.healthLine = entCfg.healthLine or 4
    entCfg.healthShowMax = entCfg.healthShowMax ~= false

    for lineNum = 1, LINE_COUNT do
        local lineKey = "line" .. lineNum
        local lineCfg = entCfg[lineKey] or {}

        lineCfg.text = lineCfg.text or ""
        lineCfg.font = lineCfg.font or "DermaDefault"
        lineCfg.size = math.Clamp(lineCfg.size or 30, 8, 120)
        lineCfg.color = lineCfg.color or { r = 100, g = 100, b = 100 }
        lineCfg.dropShadow = lineCfg.dropShadow ~= false

        entCfg[lineKey] = lineCfg

        local isHealthLine = entCfg.healthLine == lineNum

        -- Line header
        local lineHeader = vgui.Create("DLabel", scroll)
        lineHeader:Dock(TOP)
        lineHeader:SetTall(20)
        lineHeader:DockMargin(12, 4, 0, 0)
        lineHeader:SetFont("DermaDefaultBold")
        lineHeader:SetTextColor(Color(180, 180, 200))
        lineHeader:SetText("Line " .. lineNum .. (isHealthLine and " (Health)" or ""))

        -- Text row
        local textRow = vgui.Create("DPanel", scroll)
        textRow:Dock(TOP)
        textRow:SetTall(28)
        textRow:DockMargin(0, 2, 0, 0)

        textRow.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        end

        local textLabel = vgui.Create("DLabel", textRow)
        textLabel:SetText("Text")
        textLabel:Dock(LEFT)
        textLabel:SetWide(140)
        textLabel:SetFont("DermaDefault")
        textLabel:SetTextColor(Color(200, 200, 220))
        textLabel:DockMargin(8, 0, 0, 0)

        local textEntry = vgui.Create("DTextEntry", textRow)
        textEntry:Dock(FILL)
        textEntry:DockMargin(4, 4, 4, 4)
        textEntry:SetText(lineCfg.text)

        textEntry.OnChange = function(self)
            lineCfg.text = self:GetValue()
        end

        -- Font row
        local fontRow = vgui.Create("DPanel", scroll)
        fontRow:Dock(TOP)
        fontRow:SetTall(28)
        fontRow:DockMargin(0, 2, 0, 0)

        fontRow.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        end

        local fontLabel = vgui.Create("DLabel", fontRow)
        fontLabel:SetText("Font")
        fontLabel:Dock(LEFT)
        fontLabel:SetWide(140)
        fontLabel:SetFont("DermaDefault")
        fontLabel:SetTextColor(Color(200, 200, 220))
        fontLabel:DockMargin(8, 0, 0, 0)

        local fontCombo = vgui.Create("DComboBox", fontRow)
        fontCombo:Dock(FILL)
        fontCombo:DockMargin(4, 4, 4, 4)

        fontCombo:AddChoice("ChatFont")
        fontCombo:AddChoice("CreditsText")
        fontCombo:AddChoice("DermaDefault")
        fontCombo:AddChoice("DermaLarge")
        fontCombo:AddChoice("HudDefault")
        fontCombo:AddChoice("DermaDefault")
        fontCombo:AddChoice("Trebuchet18")

        fontCombo:SetValue(lineCfg.font)

        fontCombo.OnSelect = function(_, _, val)
            lineCfg.font = val
        end

        -- Size row
        local sizeRow = vgui.Create("DPanel", scroll)
        sizeRow:Dock(TOP)
        sizeRow:SetTall(32)
        sizeRow:DockMargin(0, 2, 0, 0)

        sizeRow.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        end

        local sizeLabel = vgui.Create("DLabel", sizeRow)
        sizeLabel:SetText("Size")
        sizeLabel:Dock(LEFT)
        sizeLabel:SetWide(40)
        sizeLabel:SetFont("DermaDefault")
        sizeLabel:SetTextColor(Color(200, 200, 220))
        sizeLabel:DockMargin(8, 0, 0, 0)

        local sizeSlider = vgui.Create("DNumSlider", sizeRow)
        sizeSlider:Dock(FILL)
        sizeSlider:DockMargin(4, 4, 8, 4)
        sizeSlider:SetMin(8)
        sizeSlider:SetMax(120)
        sizeSlider:SetDecimals(0)
        sizeSlider:SetValue(lineCfg.size or 30)
        sizeSlider.Label:SetText("")
        sizeSlider.TextArea:SetNumeric(true)

        if IsValid(sizeSlider.TextArea) then
            sizeSlider.TextArea:SetTextColor(Color(255, 255, 255))
            sizeSlider.TextArea:SetDrawBackground(true)
        end

        sizeSlider.OnValueChanged = function(_, val)
            lineCfg.size = math.floor(val)
        end

        -- Color row
        local colorRow = vgui.Create("DPanel", scroll)
        colorRow:Dock(TOP)
        colorRow:SetTall(28)
        colorRow:DockMargin(0, 2, 0, 0)

        colorRow.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        end

        local colorLabel = vgui.Create("DLabel", colorRow)
        colorLabel:SetText("Color")
        colorLabel:Dock(LEFT)
        colorLabel:SetWide(140)
        colorLabel:SetFont("DermaDefault")
        colorLabel:SetTextColor(Color(200, 200, 220))
        colorLabel:DockMargin(8, 0, 0, 0)

        local colorDisplay = vgui.Create("DPanel", colorRow)
        colorDisplay:Dock(RIGHT)
        colorDisplay:SetWide(60)
        colorDisplay:DockMargin(4, 4, 4, 4)

        colorDisplay.Paint = function(_, w, h)
            local c = lineCfg.color
            draw.RoundedBox(4, 0, 0, w, h, Color(c.r, c.g, c.b))
        end

        local colorBtn = vgui.Create("DButton", colorRow)
        colorBtn:Dock(FILL)
        -- colorBtn:DockMargin(4, 4, 4, 4)
        colorBtn:DockMargin(0, 4, 0, 4)
        colorBtn:SetText("")
        colorBtn:SetImage("icon16/palette.png")

        colorBtn.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h,
                self:IsHovered() and Color(100, 120, 150) or Color(60, 80, 110)
            )
        end

        colorBtn.DoClick = function()
            local frame = vgui.Create("DFrame")
            frame:SetTitle("Pick Color")
            frame:SetSize(300, 300)
            frame:Center()
            frame:MakePopup()

            local mixer = vgui.Create("DColorMixer", frame)
            mixer:Dock(FILL)
            mixer:DockMargin(4, 24, 4, 4)
            mixer:SetColor(Color(lineCfg.color.r, lineCfg.color.g, lineCfg.color.b))

            mixer.ValueChanged = function(self)
                local c = self:GetColor()
                lineCfg.color.r = c.r
                lineCfg.color.g = c.g
                lineCfg.color.b = c.b
                colorDisplay:InvalidateLayout()
            end
        end

        -- Drop shadow row
        local shadowRow = vgui.Create("DPanel", scroll)
        shadowRow:Dock(TOP)
        shadowRow:SetTall(28)
        shadowRow:DockMargin(0, 2, 0, 8)

        shadowRow.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
        end

        local shadowLabel = vgui.Create("DLabel", shadowRow)
        shadowLabel:SetText("Drop Shadow")
        shadowLabel:Dock(LEFT)
        shadowLabel:SetWide(140)
        shadowLabel:SetFont("DermaDefault")
        shadowLabel:SetTextColor(Color(200, 200, 220))
        shadowLabel:DockMargin(8, 0, 0, 0)

        local shadowCheck = vgui.Create("DCheckBoxLabel", shadowRow)
        shadowCheck:Dock(RIGHT)
        shadowCheck:SetWide(120)
        shadowCheck:DockMargin(4, 4, 4, 4)
        shadowCheck:SetText("")
        shadowCheck:SetFont("DermaDefault")
        shadowCheck:SetTextColor(Color(200, 200, 220))
        shadowCheck:SetChecked(lineCfg.dropShadow)

        shadowCheck.OnChange = function(self)
            lineCfg.dropShadow = self:GetChecked()
        end
    end
end

-- ============================================================
-- MAIN PANEL
-- ============================================================

local function BuildPanel(CPanel)

    CPanel:ClearControls()
    CPanel:Help("Universal Ammo - Admin Panel")

    local wrapper = vgui.Create("DPanel")
    wrapper:Dock(FILL)
    wrapper:SetTall(ScrH() * 0.8)
    wrapper.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 50))
    end
    CPanel:AddItem(wrapper)

    local tabBar = vgui.Create("DPanel", wrapper)
    tabBar:Dock(TOP)
    tabBar:SetTall(54)
    tabBar:DockMargin(8, 8, 8, 8)
    tabBar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 65))
    end

    local content = vgui.Create("DPanel", wrapper)
    content:Dock(FILL)
    content:DockMargin(8, 0, 8, 8)
    content.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 55))
    end

    local cfg

    local function GetFresh()
        cfg = table.Copy(UniversalAmmo.Config or {})
    end

    GetFresh()

    SwitchRef = function(tab, force)
        activeTab = tab or activeTab
        GetFresh()

        content:Clear()

        local scroll = vgui.Create("DScrollPanel", content)
        scroll:Dock(FILL)
        scroll:DockMargin(8, 8, 8, 8)

        if activeTab == "Box" then
            EntityTab(scroll, cfg.box, "Box")
            EntityLabel(scroll, cfg, "box", "Box")

        elseif activeTab == "Inf. Crate" then
            EntityTab(scroll, cfg.crate, "Crate")
            EntityLabel(scroll, cfg, "crate", "Crate")

        elseif activeTab == "Vend. Machine" then
            EntityTab(scroll, cfg.vend, "Machine")
            EntityLabel(scroll, cfg, "vend", "Machine")

        elseif activeTab == "General" then
            Header(scroll, "General Items")
            Description(scroll, "Configure general item addons (medical, utility, etc.) and their properties.")
            
            local list = {}
            for _, v in ipairs(cfg.general.items or {}) do
                table.insert(list, { addon = v.addon, name = v.name, value = v.value })
            end

            ListEditorMedical(scroll, "General Items", list, function(v)
                cfg.general.items = v
            end, "Addon class (e.g., fas2_ifak)", "Item name (e.g., Hemostats)")

        elseif activeTab == "Ammo Overrides" then
            Header(scroll, "Ammo Overrides")
            Description(scroll, "Override default ammo amounts for specific weapon types.")
            local list = {}
            for k,v in pairs(cfg.ammoOverrides or {}) do
                table.insert(list, { name = k, value = v })
            end

            ListEditor(scroll, "Overrides", list, function(v)
                cfg.ammoOverrides = {}
                for _, x in ipairs(v) do
                    cfg.ammoOverrides[x.name] = tonumber(x.value) or 0
                end
            end, "Ammo type (e.g., pistol)", "Amount override")


        elseif activeTab == "Filter" then
            Header(scroll, "Filter")
            Description(scroll, "Restrict which weapons can use this entity using whitelist or blacklist modes.")
            Header(scroll, "Filter Mode")
            
            local modeRow = vgui.Create("DPanel", scroll)
            modeRow:Dock(TOP)
            modeRow:SetTall(28)
            modeRow:DockMargin(0, 4, 0, 0)
            modeRow.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 60))
                draw.RoundedBox(4, 0, 0, w, h, Color(65, 65, 85), false)
            end

            local modeLabel = vgui.Create("DLabel", modeRow)
            modeLabel:SetText("Mode")
            modeLabel:Dock(LEFT)
            modeLabel:SetWide(140)
            modeLabel:SetFont("DermaDefault")
            modeLabel:SetTextColor(Color(200, 200, 220))
            modeLabel:DockMargin(8, 0, 0, 0)

            local modeDropdown = vgui.Create("DComboBox", modeRow)
            modeDropdown:Dock(FILL)
            modeDropdown:AddChoice("None (Allow All)", "none")
            modeDropdown:AddChoice("Whitelist (Enable)", "whitelist")
            modeDropdown:AddChoice("Blacklist (Disable)", "blacklist")
            modeDropdown:SetValue(cfg.listMode)
            modeDropdown:DockMargin(8, 4, 8, 4)
            modeDropdown:SetTooltip("Select filter mode: None=all weapons, Whitelist=only listed, Blacklist=all except listed")

            modeDropdown.OnSelect = function(self, index, value, data)
                cfg.listMode = data
            end

            local list = {}
            for _, v in ipairs(cfg.listItems or {}) do
                table.insert(list, { name = v })
            end

            ListEditorWeapons(scroll, "Weapons", list, function(v)
                cfg.listItems = {}
                for _, x in ipairs(v) do
                    table.insert(cfg.listItems, x.name)
                end
            end, "Weapon class (e.g., weapon_pistol)")
        end
    end

    local tabs = {
        { name = "Box", row = 1 },
        { name = "Inf. Crate", row = 1 },
        { name = "Vend. Machine", row = 1 },
        { name = "General", row = 2 },
        { name = "Ammo Overrides", row = 2 },
        { name = "Filter", row = 2 }
    }

    local rows = {}
    for _, tab in ipairs(tabs) do
        if not rows[tab.row] then
            local row = vgui.Create("DPanel", tabBar)
            row:Dock(TOP)
            row:SetTall(22)
            row:DockMargin(0, tab.row == 1 and 0 or 4, 0, 0)
            row.Paint = nil
            rows[tab.row] = row
        end
    end

    for _, tab in ipairs(tabs) do
        local b = vgui.Create("DButton", rows[tab.row])
        
        b:SetText(tab.name)
        b:SetFont("DermaDefaultBold")
        b:Dock(LEFT)
        b:DockMargin(0, 0, 8, 0)
        
        -- Measure text width to size button appropriately
        surface.SetFont("DermaDefaultBold")
        local textW, textH = surface.GetTextSize(tab.name)
        b:SetWide(textW + 16)

        b.Paint = function(self, w, h)
            local isActive = activeTab == tab.name
            local bgColor = isActive and Color(80, 140, 200) or (self:IsHovered() and Color(100, 110, 130) or Color(60, 70, 90))
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            draw.RoundedBox(4, 0, 0, w, h, Color(150, 160, 180), false)
        end

        b.DoClick = function()
            SwitchRef(tab.name)
        end
    end

    SwitchRef("Box")

    local resetAll = vgui.Create("DButton", wrapper)
    resetAll:Dock(BOTTOM)
    resetAll:SetTall(32)
    resetAll:SetText("Reset All to Defaults")
    resetAll:DockMargin(8, 0, 8, 8)
    resetAll:SetFont("DermaDefaultBold")
    resetAll:SetTooltip("This will reset ALL settings to defaults, including all tabs. Use with caution.")
    resetAll:SetImage("icon16/exclamation.png")

    resetAll.Paint = function(self, w, h)
        local bg = self:IsHovered() and Color(140, 40, 40) or Color(90, 25, 25)

        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.RoundedBox(4, 0, 0, w, h, Color(200, 80, 80, 30))
    end

    resetAll.DoClick = function()
        CenteredQuery(
            "WARNING:\n\nThis will permanently reset EVERYTHING.\n\nAll tabs, all settings, all customization will be lost.",
            "CONFIRM FULL WIPE",
            function()
                CenteredQuery(
                    "Final confirmation:\n\nThis action cannot be undone.",
                    "FINAL CONFIRMATION",
                    function()
                        net.Start("UA_ResetConfig")
                        net.SendToServer()
                    end
                )
            end
        )
    end

    local reset = vgui.Create("DButton", wrapper)
    reset:Dock(BOTTOM)
    reset:SetTall(32)
    reset:SetText("Reset to Defaults")
    reset:DockMargin(8, 4, 8, 4)
    reset:SetFont("DermaDefaultBold")
    reset:SetTooltip("This will reset the current tab's settings to defaults. Other tabs will be unaffected.")
    reset:SetImage("icon16/arrow_refresh.png")

    reset.Paint = function(self, w, h)
        local bg = self:IsHovered() and Color(210, 90, 90) or Color(160, 60, 60)

        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.RoundedBox(4, 0, 0, w, h, Color(220, 140, 140, 40))
    end

    reset.DoClick = function()
        CenteredQuery(
            "This will reset the current tab's settings to defaults. Continue?\n\nAffected tab: " .. activeTab,
            "Confirm Reset",
            function()
                net.Start("UA_ResetTab")
                net.WriteString(string.lower(activeTab))
                net.SendToServer()
            end
        )
    end

    local save = vgui.Create("DButton", wrapper)
    save:Dock(BOTTOM)
    save:SetTall(32)
    save:SetText("Save Configuration")
    save:DockMargin(8, 4, 8, 4)
    save:SetFont("DermaDefaultBold")

    save.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(100, 180, 100) or Color(70, 140, 70)
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        draw.RoundedBox(4, 0, 0, w, h, Color(150, 200, 150), false)
    end

    save.DoClick = function()
        net.Start("UA_SaveConfig")
        net.WriteString(UniversalAmmo.SerializeConfig(cfg))
        net.SendToServer()
    end
end

hook.Add("PopulateToolMenu", "UA_Admin", function()
    spawnmenu.AddToolMenuOption(
        "Utilities",
        "Universal Ammo",
        "ua_admin",
        "Admin Panel",
        "", "", BuildPanel
    )
end)