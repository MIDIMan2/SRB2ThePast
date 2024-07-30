------------------------------------
--SRB2:TP Era Skins: Miscellaneous-- // MIDIMan, based off of code from Barrels O' Fun
------------------------------------

local steamskins = { 
	S_STEAM1,			// 2.2
	S_OLD_STEAM_SPAWN	// Demo 3 - 2.1
}

local function SteamItemSkin(m,mt,list)
	if not (m and m.valid and mt and mt.valid) then return end
	
	local itemskin = mt.extrainfo
	if udmf then
		itemskin = mt.args[1]
	end

	if m.itemskin == nil or m.itemskin == 0 then
		m.itemskin = itemskin
	end

	if m.itemskin != 0 then
		m.skintable = list
		if m.state != list[min(m.itemskin,#list)][1] then
			m.state = list[min(m.itemskin,#list)][1]
		end
	else
		if leveltime == 0 then	-- Only update once at map load.
			SRB2TP_UpdateObject(m)
		else					-- If any are spawned after that update them.
			SRB2TP_UpdateObject(m,true)
		end
		
		m.state = mobjinfo[m.type].spawnstate
	end
end

addHook("MapThingSpawn", function(m,mt) 
	SteamItemSkin(m,mt,steamskins)
end, MT_STEAM)

-- TODO: Maybe add a TouchSpecial hook when 2.2.14 is out
addHook("MobjCollide", function(thing, tmthing)
	if not (thing and thing.valid and tmthing and tmthing.valid) then return end
	if thing.state ~= S_OLD_STEAM_SPAWN then return end
	
	-- Height check
	if not (thing.z + thing.height >= tmthing.z
	and tmthing.z + tmthing.height >= thing.z) then
		return
	end
	
	local player = tmthing.player
	if not ((player and player.valid) or (tmthing.flags & MF_PUSHABLE)) then return end
	
	local speed = thing.info.mass
	local flipval = P_MobjFlip(thing)
	
	tmthing.eflags = $|MFE_SPRUNG
	tmthing.momz = flipval * FixedMul(speed, FixedSqrt(FixedMul(thing.scale, tmthing.scale)))
	
	if player and player.valid then
		P_ResetPlayer(player)
		if player.panim ~= PA_FALL then
			tmthing.state = S_PLAY_FALL
		end
	end
end, MT_STEAM)
