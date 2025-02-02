erchius_fuel_from_erchius_crystals_fuInit = init

function init()
	erchius_fuel_from_erchius_crystals_fuInit()

	-- if peerless liquids is researched, give the liquid erchius fuel recipe
	if isResearched("fu_chemistry", "LIQUIDCRAFTING3") then
		if not player.blueprintKnown("liquidfuel") then
			player.giveBlueprint("liquidfuel")
		end
	end
end