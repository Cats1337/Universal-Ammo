AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local cooldown = {}

function ENT:Initialize()
    local cfg = UniversalAmmo.Config.crate

    self:SetModel(cfg.model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetHealth(cfg.maxHealth or 100)
end

function ENT:OnTakeDamage(dmg)
    if UniversalAmmo.Config.crate.maxHealth == 0 then return end

    self:SetHealth(self:Health() - dmg:GetDamage())
    if self:Health() <= 0 then
        self:Remove()
    end
end

local function IsOnCooldown(ply, cd)
    cooldown[ply] = cooldown[ply] or 0

    if cooldown[ply] > CurTime() then
        return true
    end

    cooldown[ply] = CurTime() + (cd or 0)
    return false
end

function ENT:Use(_, caller)
    if self._Consumed then return end
    if not IsValid(caller) or not caller:IsPlayer() then return end
    if not UniversalAmmo.Config.crate.enabled then return end

    local cfg = UniversalAmmo.Config.crate

    if IsOnCooldown(caller, cfg.cooldown or 0) then return end

    local wep = caller:GetActiveWeapon()
    if not IsValid(wep) then return end

    local class = wep:GetClass()

    if not UniversalAmmo.IsAllowed(class) then
        -- caller:ChatPrint("That weapon is not allowed to receive ammo.")
        UniversalAmmo.Notify(caller, "That weapon is not allowed to receive ammo.", 1, 3)
        surface.PlaySound( "buttons/button15.wav" )
        cooldown[caller] = CurTime() + 1
        return
    end

    local adv = cfg.advancedOverride and cfg.advancedOverride.items

    -- ============================================================
    -- ADVANCED OVERRIDES
    -- ============================================================
    if istable(adv) then
        local gave = false

        for _, item in ipairs(adv) do
            if item.weaponClass == class then
                caller:GiveAmmo(
                    tonumber(item.amount) or 0,
                    item.ammoName,
                    true
                )
                gave = true
            end
        end

        if gave then
            return
        end
    end

    -- ============================================================
    -- NORMAL AMMO FLOW
    -- ============================================================
    local ammoType = wep:GetPrimaryAmmoType()
    local altAmmoType = wep:GetSecondaryAmmoType()
    if ammoType == -1 then
        UniversalAmmo.Notify(caller, "This weapon does not use ammo.", 0, 3)
        cooldown[caller] = CurTime() + 1
        return
    end

    local ammoName = game.GetAmmoName(ammoType)
    local altAmmoName = game.GetAmmoName(altAmmoType)
    if not ammoName then
        UniversalAmmo.Notify(caller, "Unknown ammo type.", 3, 3)
        cooldown[caller] = CurTime() + 1
        return
    end

    local amount = UniversalAmmo.GetAmmoAmount(ammoName, wep, "crate")
    caller:GiveAmmo(amount, ammoName, false)
    
    local altAmount = UniversalAmmo.GetAmmoAmount(altAmmoName, wep, "crate") / 7
    if altAmmoName then
        caller:GiveAmmo(altAmount, altAmmoName, false)
    end
end