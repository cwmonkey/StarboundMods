learn_beeflower_from_agriculture_fuInit = init

function init()
	learn_beeflower_from_agriculture_fuInit()

	-- if basic crops is researched, give the spring flower recipe
	if isResearched("fu_agriculture", "CROPS2") then
		if not player.blueprintKnown("beeflower") then
			player.giveBlueprint("beeflower")
		end
	end
end