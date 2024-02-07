oldInit = init

function init()
	oldInit()

	-- if basic crops is researched, give the spring flower recipe
	if isResearched("fu_agriculture", "CROPS1") then
		if not player.blueprintKnown("flowerspring") then
			player.giveBlueprint("flowerspring")
		end
	end
end