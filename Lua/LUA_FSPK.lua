-- Old Spike - Ported from 2.1 (with 2.2 improvements) by MIDIMan for SRB2TP

freeslot(
	"SPR_FSPK", -- SPR_OSPK is used by the old ring sparkle object, so use an abbreviation of "Floor Spike" instead
	"MT_OLD_SPIKE",
	"S_OLD_SPIKE1",
	"S_OLD_SPIKE2",
	"S_OLD_SPIKE3",
	"S_OLD_SPIKE4",
	"S_OLD_SPIKE5",
	"S_OLD_SPIKE6",
	"S_OLD_SPIKED1",
	"S_OLD_SPIKED2"
)

local TP_TMSF_RETRACTED = 1
local TP_TMSF_INTANGIBLE = 1<<1

addHook("MapThingSpawn", function(mo, mthing)
	if not (mo and mo.valid and mthing and mthing.valid) then return end
	
	-- Setup for UDMF and non-UDMF maps
	local retractSpeed = mthing.args[0]
	local fuse = mthing.args[1]
	local flags = 0
	
	if not udmf then
		if (mthing.options & MTF_OBJECTSPECIAL) then
			retractSpeed = mobjinfo[MT_OLD_SPIKE].speed + mthing.angle
			if (mthing.options & MTF_EXTRA) then
				flags = $|TP_TMSF_RETRACTED
			end
		end
		fuse = (16 - mthing.extrainfo) * retractSpeed/16
		
		if (mthing.options & MTF_AMBUSH) then
			flags = $|TP_TMSF_INTANGIBLE
		end
	else
		flags = mthing.args[2]
	end
	
	-- Pop up spikes!
	if retractSpeed then
		mo.flags = $ & ~MF_SCENERY
		mo.fuse = fuse
	end
	if (flags & TP_TMSF_RETRACTED) then
		mo.state = mo.info.meleestate
	end
	-- Use per-thing collision for spikes unless the intangible flag is checked.
	if not (flags & TP_TMSF_INTANGIBLE) and not metalrecording then
		 mo.flags = ($|MF_SOLID) & ~(MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPHEIGHT)
	end
end, MT_OLD_SPIKE)

addHook("MobjThinker", function(mo)
	if not (mo and mo.valid) then return end
	
	if not mo.health and (mo.z <= mo.floorz or mo.z + mo.height >= mo.ceilingz) then
		P_RemoveMobj(mo)
		return
	end
end, MT_OLD_SPIKE)

addHook("MobjFuse", function(mo)
	if not (mo and mo.valid) then return end
	
	mo.state = states[mo.state].nextstate
	if not mo.valid then
		return
	end
	
	mo.fuse = mo.info.speed
	if mo.spawnpoint and mo.spawnpoint.valid then
		if not udmf then
			mo.fuse = $ + mo.spawnpoint.angle
		else
			mo.fuse = mo.spawnpoint.args[0]
		end
	end
	
	return true
end, MT_OLD_SPIKE)

addHook("MobjCollide", function(thing, tmthing)
	if not (thing and thing.valid and tmthing and tmthing.valid) then return end
	
	if tmthing.type == MT_METALSONIC_RACE or (tmthing.player and tmthing.player.valid and (tmthing.player.powers[pw_strong] & STR_SPIKE)) then
		if tmthing.z > thing.z + thing.height
		or tmthing.z + tmthing.height < thing.z then
			return false
		end
		
		S_StartSound(tmthing, thing.info.deathsound)
		if thing.subsector and thing.subsector.valid and thing.subsector.sector and thing.subsector.sector.valid then
			for iter in thing.subsector.sector.thinglist() do
				if iter.type == MT_OLD_SPIKE and iter.health > 0 and (iter.flags & MF_SOLID) and P_AproxDistance(iter.x - tmthing.x, iter.y - tmthing.y) < 56*iter.scale then
					P_KillMobj(iter, tmthing, tmthing)
				end
			end
		end
		return false
	end
	
	if (thing.flags & MF_SOLID) and tmthing.player and tmthing.player.valid then
		if (thing.eflags & MFE_VERTICALFLIP) then
			if tmthing.z + tmthing.height <= thing.z - thing.scale
			and tmthing.z + tmthing.height + tmthing.momz >= thing.z - thing.scale-- + thing.momz
			and not (tmthing.player.charability == CA_BOUNCE and tmthing.player.panim == PA_ABILITY and (tmthing.eflags & MFE_VERTICALFLIP)) then
				P_DamageMobj(tmthing, thing, thing, 1, DMG_SPIKE)
			end
		elseif tmthing.z >= thing.z + thing.height + thing.scale
		and tmthing.z + tmthing.momz <= thing.z + thing.height + thing.scale-- + thing.momz
		and not (tmthing.player.charability == CA_BOUNCE and tmthing.player.panim == PA_ABILITY and not (tmthing.eflags & MFE_VERTICALFLIP)) then
			P_DamageMobj(tmthing, thing, thing, 1, DMG_SPIKE)
		end
	end
end, MT_OLD_SPIKE)

addHook("MobjMoveCollide", function(tmthing, thing)
	if not (tmthing and tmthing.valid and thing and thing.valid) then return end
	
	-- When solid spikes move, assume they just popped up and teleport things on top of them to hurt.
	-- TODO: Figure out why this can hurt Fang when the spike pops up, unlike the vanilla spike
	if (thing.flags & MF_SOLID) and (tmthing.flags & MF_SOLID) then
		if thing.z > tmthing.z + tmthing.height
		or thing.z + thing.height < tmthing.z then
			return false
		end
		
		if (tmthing.eflags & MFE_VERTICALFLIP) then
			P_SetOrigin(thing, thing.x, thing.y, tmthing.z - thing.height - tmthing.scale)
		else
			P_SetOrigin(thing, thing.x, thing.y, tmthing.z + tmthing.height + tmthing.scale)
		end
		if (thing.flags & MF_SHOOTABLE) then
			P_DamageMobj(thing, tmthing, tmthing, 1, DMG_SPIKE)
		end
		return false
	end
	
	if (tmthing.flags & MF_SOLID) and thing.player and thing.player.valid then
		if (tmthing.eflags & MFE_VERTICALFLIP) then
			if thing.z + thing.height <= tmthing.z + tmthing.scale
			and thing.z + thing.height + thing.momz >= tmthing.z + tmthing.scale + tmthing.momz
			and not (thing.player.charability == CA_BOUNCE and thing.player.panim == PA_ABILITY and (thing.eflags & MFE_VERTICALFLIP)) then
				P_DamageMobj(thing, tmthing, tmthing, 1, DMG_SPIKE)
			end
		elseif thing.z >= tmthing.z + tmthing.height - tmthing.scale
		and thing.z + thing.momz <= tmthing.z + tmthing.height - tmthing.scale + tmthing.momz
		and not (thing.player.charability == CA_BOUNCE and thing.player.panim == PA_ABILITY and not (thing.eflags & MFE_VERTICALFLIP)) then
			P_DamageMobj(thing, tmthing, tmthing, 1, DMG_SPIKE)
		end
	end
end, MT_OLD_SPIKE)

-- This code is ported from 2.2, but is nearly functionally identical to 2.1's code
addHook("MobjDeath", function(target, inflictor, _, _, _)
	if not (target and target.valid and inflictor and inflictor.valid) then return end
	
	local ang = ANGLE_90
	if inflictor and inflictor.valid then ang = $ + inflictor.angle end
	local scale = target.scale
	local xoffs, yoffs = P_ReturnThrustX(target, ang, 8*scale), P_ReturnThrustY(target, ang, 8*scale)
	local flip = (target.eflags & MFE_VERTICALFLIP)
	local chunk
	local momz = 0
	
	S_StartSound(target, target.info.deathsound)
	
	if target.info.deathstate ~= S_NULL then
		momz = 6*scale
		if flip then momz = -$ end
		
		local function makechunk(angtweak, xmov, ymov)
			chunk = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_OLD_SPIKE)
			if chunk and chunk.valid then
				chunk.state = target.info.xdeathstate
				chunk.health = 0
				chunk.angle = angtweak
				
				chunk.flags = MF_NOCLIP
				P_SetOrigin(chunk, chunk.x + xmov, chunk.y + ymov, chunk.z)
				
				P_InstaThrust(chunk, chunk.angle, 4*scale)
				chunk.momz = momz
			end
		end
		
		makechunk(ang + ANGLE_180, -xoffs, -yoffs)
		makechunk(ang, xoffs, yoffs)
	end
	
	momz = 7*scale
	if flip then momz = -$ end
	
	local zoffs = 12*scale
	if flip then zoffs = -$ end
	
	chunk = P_SpawnMobjFromMobj(target,  0, 0, 0, MT_OLD_SPIKE)
	if chunk and chunk.valid then
		chunk.state = target.info.deathstate
		chunk.health = 0
		chunk.angle = ang + ANGLE_180
		
		chunk.flags = MF_NOCLIP
		P_SetOrigin(chunk, chunk.x - xoffs, chunk.y - yoffs, chunk.z + zoffs)
		
		P_InstaThrust(chunk, chunk.angle, 2*scale)
		chunk.momz = momz
	end
	
	target.state = target.info.deathstate
	target.health = 0
	target.angle = ang
	
	target.flags = MF_NOCLIP
	P_SetOrigin(target, target.x + xoffs, target.y + yoffs, target.z + zoffs)
	
	P_InstaThrust(target, target.angle, 2*scale)
	target.momz = momz
	
	return true
end, MT_OLD_SPIKE)

mobjinfo[MT_OLD_SPIKE] = {
	--$Name Old Spike
	--$Sprite FSPKA0
	--$Category Old Hazards
	--$Flags1Text Start retracted
	--$Flags4Text Retractable
	--$Flags8Text Intangible
	--$AngleText Retraction invertal
	--$ParameterText Start delay
	--$Arg0 Retraction interval
	--$Arg1 Start interval
	--$Arg2 Flags
	--$Arg2Type 12
	--$Arg2Enum {1 = "Start retracted"; 2 = "Intangible";}
	doomednum = 525,
	spawnstate = S_OLD_SPIKE1,
	spawnhealth = 1000,
	reactiontime = 8,
	painsound = sfx_s3k64,
	meleestate = S_OLD_SPIKE4,
	deathstate = S_OLD_SPIKED1,
	xdeathstate = S_OLD_SPIKED2,
	deathsound = sfx_mspogo,
	speed = 2*TICRATE,
	radius = 8*FRACUNIT, -- 1*FRACUNIT before 2.0
	height = 32*FRACUNIT, -- 42*FRACUNIT before 2.1
	mass = DMG_SPIKE,
	flags = MF_NOBLOCKMAP|MF_SCENERY|MF_NOCLIPHEIGHT
}

states[S_OLD_SPIKE1]	=	{SPR_FSPK,	A,	-1,	A_SpikeRetract,	1,	0,	S_OLD_SPIKE2}
states[S_OLD_SPIKE2]	=	{SPR_FSPK,	F,	2,	A_Pain,			0,	0,	S_OLD_SPIKE3}
states[S_OLD_SPIKE3]	=	{SPR_FSPK,	E,	2,	nil,			0,	0,	S_OLD_SPIKE4}
states[S_OLD_SPIKE4]	=	{SPR_FSPK,	D,	-1,	A_SpikeRetract,	0,	0,	S_OLD_SPIKE5}
states[S_OLD_SPIKE5]	=	{SPR_FSPK,	E,	2,	A_Pain,			0,	0,	S_OLD_SPIKE6}
states[S_OLD_SPIKE6]	=	{SPR_FSPK,	F,	2,	nil,			0,	0,	S_OLD_SPIKE1}
states[S_OLD_SPIKED1]	=	{SPR_FSPK,	B,	-1,	nil,			0,	0,	S_NULL}
states[S_OLD_SPIKED2]	=	{SPR_FSPK,	C,	-1,	nil,			0,	0,	S_NULL}
