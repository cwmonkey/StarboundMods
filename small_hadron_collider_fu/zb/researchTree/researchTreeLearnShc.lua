small_hadron_collider_fuInit = init

function init()
	small_hadron_collider_fuInit()

	-- if "fission" is researched, give the shc recipe
	if isResearched("fu_power", "FISSION") then
		if not player.blueprintKnown("shc") then
			player.giveBlueprint("shc")
		end
	end
end