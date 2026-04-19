require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="standard_issue_explorerset"

armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "protoImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "maxBreath", amount = 36000}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end