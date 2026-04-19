require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="standard_issue_spacesuitset"

armorBonus={
	{stat = "maxBreath", amount = 72000}
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