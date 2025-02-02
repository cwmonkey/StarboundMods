small_hadron_collider_fuInit = init

function init()
	small_hadron_collider_fuInit()

	-- if basic crops is researched, give the spring flower recipe
	if isResearched("fu_power", "FISSION") then
		if not player.blueprintKnown("shc") then
			player.giveBlueprint("shc")
		end
	end
end