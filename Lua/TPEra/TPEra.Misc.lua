------------------------------------
--SRB2:TP Era Skins: Miscellaneous-- // MIDIMan, based off of code from Barrels O' Fun
------------------------------------

local steamskins = { 
	S_STEAM1,			// 2.2
	S_OLD_STEAM_SPAWN	// Demo 3 - 2.1
}

local function SteamItemSkin(m,mt,list)
	
	local itemskin = mt.extrainfo
	if udmf
		itemskin = mt.args[1]
	end

	if m.itemskin == nil or m.itemskin == 0
		m.itemskin = itemskin
	end

	if m.itemskin != 0
		m.skintable = list
		if m.state != list[min(m.itemskin,#list)][1]
			m.state = list[min(m.itemskin,#list)][1]
		end
	else

		if leveltime == 0 	-- Only update once at map load.
			SRB2TP_UpdateObject(m)
		else				-- If any are spawned after that update them.
			SRB2TP_UpdateObject(m,true)
		end

		m.state = mobjinfo[m.type].spawnstate
	end
end

addHook("MapThingSpawn", function(m,mt) 
	SteamItemSkin(m,mt,steamskins)
end, MT_STEAM)
