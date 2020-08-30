local hideTable = import('/lua/sim/BuffDefinitions.lua').HideTable

local oldUnit = Unit
Unit = Class(oldUnit) {

-----
-- Underwater units take less damage from above water splash damage 
-----

    OnDamage = function(self, instigator, amount, vector, damageType, ...)
        if damageType == 'NormalAboveWater' and (self:GetCurrentLayer() == 'Sub' or self:GetCurrentLayer() == 'Seabed') then
            local bp = self:GetBlueprint()
            local myheight = bp.Physics.MeshExtentsY or bp.SizeY or 0
            local depth = math.abs(vector[2]) - myheight
            if depth > 1 then return 
            else
                oldUnit.OnDamage(self, instigator, amount, vector, damageType, unpack(arg))
            end
        else
            oldUnit.OnDamage(self, instigator, amount, vector, damageType, unpack(arg))
        end
    end, 

---------------    
----RECLAIM----
---------------

    --Seabed Reclaim reduced to 50% instead of 100% to make navy battles not autowin
        CreateWreckageProp = function(self, overkillRatio)
        local bp = self:GetBlueprint()

        local wreck = bp.Wreckage.Blueprint
        if not wreck then
            return nil
        end

        local mass = bp.Economy.BuildCostMass * (bp.Wreckage.MassMult or 0)
        local energy = bp.Economy.BuildCostEnergy * (bp.Wreckage.EnergyMult or 0)
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1)
        local pos = self:GetPosition()
        local layer = self:GetCurrentLayer()

        
        if layer == 'Water' or layer == 'Sub' or layer == 'Seabed' then 
            mass = mass * 0.5
            energy = energy * 0.5
        end

        local halfBuilt = self:GetFractionComplete() < 1

        if not halfBuilt and (layer == 'Air' or EntityCategoryContains(categories.NAVAL - categories.STRUCTURE, self)) then
            pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        end

        local overkillMultiplier = 1 - (overkillRatio or 1)
        mass = mass * overkillMultiplier * self:GetFractionComplete()
        energy = energy * overkillMultiplier * self:GetFractionComplete()
        time = time * overkillMultiplier

        local time  = time * 2

        local prop = Wreckage.CreateWreckage(bp, pos, self:GetOrientation(), mass, energy, time)

        if (layer ~= 'Air' and self.PlayDeathAnimation) or (layer == "Air" and halfBuilt) then
            TryCopyPose(self, prop, true)
        end

        explosion.CreateWreckageEffects(self, prop)

        return prop
    end,

--------
-- BUFFS
--------

    AddBuff = function(self, buffTable, PosEntity)
        local bt = buffTable.BuffType
        if not bt then
            return
        end

        -- When adding debuffs we have to make sure that we check for permissions
        local category = buffTable.TargetAllow and ParseEntityCategory(buffTable.TargetAllow) or categories.ALLUNITS
        if buffTable.TargetDisallow then
            category = category - ParseEntityCategory(buffTable.TargetDisallow)
        end

        if bt == 'STUN' then
            local targets
            if buffTable.Radius and buffTable.Radius > 0 then
                -- If the radius is bigger than 0 then we will use the unit as the center of the stun blast
                targets = utilities.GetTrueEnemyUnitsInCylinder(self, PosEntity or self:GetPosition(), buffTable.Radius, buffTable.Height, category)
            else
                -- The buff will be applied to the unit only
                if EntityCategoryContains(category, self) then
                    targets = {self}
                end
            end
            for _, target in targets or {} do
                -- Exclude things currently flying around if we have a flag
                if not (buffTable.ExcludeAirLayer and target:GetCurrentLayer() == 'Air') then
                    target:SetStunned(buffTable.Duration or 1)
                end
            end
        elseif bt == 'MAXHEALTH' then
            self:SetMaxHealth(self:GetMaxHealth() + (buffTable.Value or 0))
        elseif bt == 'HEALTH' then
            self:SetHealth(self, self:GetHealth() + (buffTable.Value or 0))
        elseif bt == 'SPEEDMULT' then
            self:SetSpeedMult(buffTable.Value or 0)
        elseif bt == 'MAXFUEL' then
            self:SetFuelUseTime(buffTable.Value or 0)
        elseif bt == 'FUELRATIO' then
            self:SetFuelRatio(buffTable.Value or 0)
        elseif bt == 'HEALTHREGENRATE' then
            self:SetRegenRate(buffTable.Value or 0)
        end
    end,
    
}