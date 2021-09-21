--****************************************************************************
--**
--**  File     :  /lua/sim/AdjacencyBuffs.lua
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ABMInsert = table.insert
local AdjBuffFuncs = import('/lua/sim/AdjacencyBuffFunctions.lua')

local newadj = {                -- SIZE4     SIZE8   SIZE12    SIZE16   SIZE20
    T3MassFabricator={
        MassActive=         {-0.2, -0.2, -0.2, -0.2, -0.0225}, -- ABM - made T3 Mass Fabricator give proper adjacency to small things like tml.
    },
    T1EnergyStorage={
        EnergyProduction=   {0.25, 0.125, 0.083334, 0.0625, 0.05}, -- ABM - doubled all the bonuses for the energy storage to make e storage ringing more valuable.

    },
    T1MassStorage={
        MassProduction=     {0.0625, 0.03125, 0.0208335, 0.015625, 0.0125}, -- ABM - halved all the bonuses for the mass storage to go along with the nerf to t3 mex income.

    },
}

for a, buffs in newadj do
    _G[a .. 'AdjacencyBuffs'] = {}
    for t, sizes in buffs do
        for i, add in sizes do
            local size = i * 4
            local display_name = a .. t
            local name = display_name .. 'Size' .. size
            local category = 'STRUCTURE SIZE' .. size

            if t == 'RateOfFire' and size == 4 then
                category = category .. ' ARTILLERY'
            end

            BuffBlueprint {
                Name = name,
                DisplayName = display_name,
                BuffType = string.upper(t) .. 'BONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                EntityCategory = category,
                BuffCheckFunction = AdjBuffFuncs[t .. 'BuffCheck'],
                OnBuffAffect = AdjBuffFuncs.DefaultBuffAffect,
                OnBuffRemove = AdjBuffFuncs.DefaultBuffRemove,
                Affects = {[t]={Add=add}},
                SupressDup = true,
            }
            --ABM: we add a SupressDup field which is caught by the metamethods
            --inside BuffBlueprint and removes the duplicate buff warning
            ABMInsert(_G[a .. 'AdjacencyBuffs'], name)
        end
    end
end
