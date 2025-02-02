learn_spring_flower_from_agriculture_fuInit = init

function init()
	learn_spring_flower_from_agriculture_fuInit()

	-- if basic crops is researched, give the spring flower recipe
	if isResearched("fu_agriculture", "CROPS1") then
		if not player.blueprintKnown("flowerspring") then
			player.giveBlueprint("flowerspring")
		end
	end
end