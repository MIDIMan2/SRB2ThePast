-- Old Spike - Ported from 2.1 by MIDIMan for SRB2TP

freeslot(
	"SPR_FSPK", -- SPR_OSPK is used by the old ring sparkle object, so use "Floor Spike" instead
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

mobjinfo[MT_OLD_SPIKE] = {
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
states[S_OLD_SPIKE4]	=	{SPR_FSPK,	D,	-1,	A_SpikeRetract,	1,	0,	S_OLD_SPIKE5}
states[S_OLD_SPIKE5]	=	{SPR_FSPK,	E,	2,	A_Pain,			0,	0,	S_OLD_SPIKE6}
states[S_OLD_SPIKE6]	=	{SPR_FSPK,	F,	2,	nil,			0,	0,	S_OLD_SPIKE1}
states[S_OLD_SPIKED1]	=	{SPR_FSPK,	B,	-1,	nil,			0,	0,	S_NULL}
states[S_OLD_SPIKED2]	=	{SPR_FSPK,	C,	-1,	nil,			0,	0,	S_NULL}
