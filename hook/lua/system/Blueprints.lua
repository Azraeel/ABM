
local ABMFind = table.find
local ABMCeil = math.ceil
local ABMMax = math.max

do
    
    --------------------------------------------------------------------------------
    -- Define splashy above water weapons as NormalAboveWater                                                                                
    -- Modded By: Balthazar
    --------------------------------------------------------------------------------
        
function WaterGuard(bp)
        if ABMFind(bp.Categories, 'SELECTABLE') and bp.Weapon then
            for i, weap in bp.Weapon do
                if weap.AboveWaterTargetsOnly and weap.DamageRadius and weap.DamageRadius > 1 and weap.DamageType == 'Normal' then
                        weap.DamageType = 'NormalAboveWater'
                end 
            end 
        end
end
    
    local OldModBlueprints = ModBlueprints
        
    function ModBlueprints(all_blueprints)
        OldModBlueprints(all_blueprints)
        for id,bp in all_blueprints.Unit do
            WaterGuard(bp)
                
            -- skip units without categories
            if not bp.Categories then
                continue
            end
                
            --enable stealth for all transportables, and add a special flag so we know about this
            if bp.CategoriesHash.LAND and bp.CategoriesHash.MOBILE and not bp.CategoriesHash.EXPERIMENTAL then
                if bp.Intel.RadarStealth then continue end --skip everything that already has stealth of various kinds
                if not bp.Intel then bp.Intel = {} end
                bp.Intel.RadarStealth = true
                bp.Intel.RadarStealthTransFlag = true
            end
                
        end
    end

    local oldModBlueprints = ModBlueprints
	
    function ModBlueprints(all_bps)
	
	    oldModBlueprints(all_bps)

		-- this controls the buildpower of factories and the buildtime of the units they build
		-- by multiplying the buildpower AND the time of the units they build, the overall impact
		-- of 'assisting' is divided - which helps to curb 'engineer spam'
		local buildratemod = 2
		
		-- this effectively divides the buildpower of factories so their buildpower is NOT 1 to 1 like the engineers
		-- and is the factor which controls the difference in resource usage between factories and engineers 
		-- if you reduce this value, the factories will build faster
		local factory_buildpower_ratio = 2.2
		
		-- the result of the above 2 numbers (2 * 2.2) effectively divides the buildpower of the factorys by 4.4
		-- this means that a factory with a buildpower of 40 (ie. T1 is 20 but doubled by the buildratemod) will be able
		-- to utilize 40/4.4 or 9 mass per tick

		
		--- Here is where we will try and equalize BUILD POWER for engineers building STRUCTURES 
		-- using the current mass and energy costs, we calc a new buildtime using the max mass and energy
		-- we'll use the buildtime that is the longest which means we cap mass or energy at the max rate

        --loop through the blueprints and adjust as desired.
        for id,bp in all_bps.Unit do
		
			if bp.Categories then
			
				local max_mass, max_energy
				local alt_mass, alt_energy
		
				for i, cat in bp.Categories do
				
					local reportflag = false
                    local oldtime = 0
			
                    -- structures --
					if cat == 'STRUCTURE' then
			
						for j, catj in bp.Categories do
					
							if catj == 'TECH1' then
						
								max_mass = 5
								max_energy = 50
				
								if bp.Economy.BuildTime then

									alt_mass =  bp.Economy.BuildCostMass/max_mass * 5
									alt_energy = bp.Economy.BuildCostEnergy/max_energy * 5
								
									local best_adjust = ABMCeil(ABMMax( 1, alt_mass, alt_energy))
									
									if best_adjust != ABMCeil(bp.Economy.BuildTime) then
                                    
                                        oldtime = bp.Economy.BuildTime
										bp.Economy.BuildTime = best_adjust
										reportflag = true
									end
								end
							end
					
							if catj == 'TECH2' then
						
								max_mass = 10
								max_energy = 100
							
								if bp.Economy.BuildTime then

									alt_mass =  bp.Economy.BuildCostMass/max_mass * 10
									alt_energy = bp.Economy.BuildCostEnergy/max_energy * 10									
								
									local best_adjust = ABMCeil(ABMMax( 1, alt_mass, alt_energy))
									
									if best_adjust != ABMCeil(bp.Economy.BuildTime) then
                                    
                                        oldtime = bp.Economy.BuildTime
										bp.Economy.BuildTime = best_adjust
										reportflag = true
									end
								end
							end
						
							if catj == 'TECH3' then
						
								max_mass = 15
								max_energy = 150
							
								if bp.Economy.BuildTime then

									alt_mass =  bp.Economy.BuildCostMass/max_mass * 15
									alt_energy = bp.Economy.BuildCostEnergy/max_energy * 15
								
									local best_adjust = ABMCeil(ABMMax( 1, alt_mass, alt_energy))
									
									if best_adjust != ABMCeil(bp.Economy.BuildTime) then

                                        oldtime = bp.Economy.BuildTime
										bp.Economy.BuildTime = best_adjust
										reportflag = true
									end
								end
							end

							if catj == 'EXPERIMENTAL' then
						
								max_mass = 60
								max_energy = 600

								if bp.Economy.BuildTime then
								
									alt_mass =  bp.Economy.BuildCostMass/max_mass * 60
									alt_energy = bp.Economy.BuildCostEnergy/max_energy * 60

									local best_adjust = ABMCeil(ABMMax( 1, alt_mass, alt_energy))

									if best_adjust != ABMCeil(bp.Economy.BuildTime) then
                                    
                                        oldtime = bp.Economy.BuildTime
										bp.Economy.BuildTime = best_adjust
										reportflag = true
									end
								end
							end
						end
						
						-- modify any FACTORY STRUCTURE build power and the time required to upgrade (so that upgrades remain constant)
						-- the only one this doesn't properly catch is T3 factories directly built by SUBCOMMANDERS but that's not so bad
                        -- we'll just have to say that the SACU are being 'careful' when they do that
						if ABMFind(bp.Categories, 'FACTORY') then
					
							for j, catj in bp.Categories do
						
								if catj == 'TECH1' or catj == 'EXPERIMENTAL' then
							
									if bp.Economy.BuildRate then
										bp.Economy.BuildRate = bp.Economy.BuildRate * buildratemod
										break
									end
							
								elseif catj == 'TECH2' or catj == 'TECH3' then
							
									if bp.Economy.BuildRate then
										bp.Economy.BuildRate = bp.Economy.BuildRate * buildratemod
										bp.Economy.BuildTime = bp.Economy.BuildTime * buildratemod
										break
									end
								end
							end
						end
                        
                        if bp.Economy.BuildUnit then
                            bp.Economy.BuildTime = bp.Economy.BuildTime * buildratemod * factory_buildpower_ratio
                        end
					end

                    -- units --
					if cat == 'MOBILE' then		-- ok lets handle all the factory built units and mobile experimentals
					
						-- You'll notice that I allow factory built units to build with higher energy limits (scales up thru tiers - 20,30,45)
						-- this compensates somewhat for the division of their buildpower (in particular for the energy heavy air factories)
						for j, catj in bp.Categories do
					
							if catj == 'TECH1' then
								
								local buildpower = 20	-- default T1 factory buildpower
								
								max_mass = buildpower / factory_buildpower_ratio
								max_energy = (buildpower * 20) / factory_buildpower_ratio
				
								if bp.Economy.BuildTime then

									alt_mass =  bp.Economy.BuildCostMass/max_mass		-- about 9 mass/second
									alt_energy = bp.Economy.BuildCostEnergy/max_energy	-- about 180 energy/second

									-- regardless of the mass & energy, a minimum build time of 1 second is required
									-- or else you get very wierd economy results when building the unit
									local best_adjust = ABMMax( 1, alt_mass, alt_energy)
									
									--LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower * buildratemod))

									if ABMCeil( best_adjust * buildpower * buildratemod ) != ABMCeil(bp.Economy.BuildTime) then

                                        oldtime = bp.Economy.BuildTime
                                        
										--LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower * buildratemod))									
										bp.Economy.BuildTime = best_adjust
									
										bp.Economy.BuildTime = ABMCeil(bp.Economy.BuildTime * buildpower * buildratemod)
										
										reportflag = true
									end
                                end
							end
					
							if catj == 'TECH2' then
								
								local buildpower = 35	-- default T2 factory buildpower
								
								max_mass = buildpower / factory_buildpower_ratio
								max_energy = (buildpower * 30) / factory_buildpower_ratio
							
								if bp.Economy.BuildTime then
									
									alt_mass =  bp.Economy.BuildCostMass/max_mass       -- about 16 mass/second
									alt_energy = bp.Economy.BuildCostEnergy/max_energy  -- about 480 energy/second
								
									local best_adjust = ABMMax( 1, alt_mass, alt_energy)
									
									if ABMCeil( best_adjust * buildpower * buildratemod ) != ABMCeil(bp.Economy.BuildTime) then									
									
                                        oldtime = bp.Economy.BuildTime
                                        
										--LOG("*AI DEBUG id is "..repr(catj).." "..id.."  alt_mass is "..alt_mass.."  alt_energy is "..alt_energy.." Adjusting Buildtime from "..repr(bp.Economy.BuildTime).." to "..( best_adjust * buildpower * buildratemod))
									
										bp.Economy.BuildTime = best_adjust
									
										bp.Economy.BuildTime = ABMCeil(bp.Economy.BuildTime * buildpower * buildratemod)
										
										reportflag = true
									end
								end
							end
						
							if catj == 'TECH3' then
								
								local buildpower = 50	-- default T3 factory buildpower
								
								max_mass = buildpower / factory_buildpower_ratio            -- about 23 mass/second
								max_energy = (buildpower * 45) / factory_buildpower_ratio   -- about 1030 energy/second
							
								if bp.Economy.BuildTime then

									alt_mass =  bp.Economy.BuildCostMass/max_mass
									alt_energy = bp.Economy.BuildCostEnergy/max_energy
								
									local best_adjust = ABMMax( 1, alt_mass, alt_energy)

									if ABMCeil( best_adjust * buildpower * buildratemod ) != ABMCeil(bp.Economy.BuildTime) then
									
                                        oldtime = bp.Economy.BuildTime
                                        
										bp.Economy.BuildTime = best_adjust
									
										bp.Economy.BuildTime = ABMCeil(bp.Economy.BuildTime * buildpower * buildratemod)
										
										reportflag = true
									end
								end
							end
							
							-- OK - a small problem here - No factory built experimentals - these will be the SACU built MOBILE units
                            -- as engineers they have remarkable bulidpower rates for mass compared to factories - but lower energy rates
							if catj == 'EXPERIMENTAL' then
						
								max_mass = 60
								max_energy = 600

								if bp.Economy.BuildTime then
									
									-- experimental units are not factory built so factory_buildpower_ratio is NO applied (we just use the default SACU buildpower (60)
									alt_mass =  (bp.Economy.BuildCostMass/max_mass) * 60
									alt_energy = (bp.Economy.BuildCostEnergy/max_energy) * 60
								
									local best_adjust = ABMMax( 1, alt_mass, alt_energy)
									
									if ABMCeil( best_adjust ) != ABMCeil(bp.Economy.BuildTime) then																		

										oldtime = bp.Economy.BuildTime
                                        
                                        bp.Economy.BuildTime = ABMCeil(best_adjust)
										
										reportflag = true
									end
								end
							end
						end
					end
					
					if reportflag then
					
						--LOG("*AI DEBUG class is "..cat.." "..id.." "..bp.Description.."  alt_mass is "..repr(alt_mass).."  alt_energy is "..repr(alt_energy).." Buildtime set to "..repr(bp.Economy.BuildTime).." was "..oldtime)
                        
						break
					end
				end
			end
        end
	end 
end