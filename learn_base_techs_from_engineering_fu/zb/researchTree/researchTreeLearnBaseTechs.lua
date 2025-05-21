learn_base_techs_from_engineering_fuInit = init

function init()
	learn_base_techs_from_engineering_fuInit()

	-- if basic techs are researched, give base level techs
	if isResearched("fu_engineering", "TECHS1") then
		if not player.blueprintKnown("combatmaneuvering1_tech") then
			player.giveBlueprint("combatmaneuvering1_tech")
		end

		if not player.blueprintKnown("longjump0_tech") then
			player.giveBlueprint("longjump0_tech")
		end

		if not player.blueprintKnown("distortionsphere_tech") then
			player.giveBlueprint("distortionsphere_tech")
		end

		if not player.blueprintKnown("dash_tech") then
			player.giveBlueprint("dash_tech")
		end

		if not player.blueprintKnown("doublejump") then
			player.giveBlueprint("doublejump")
		end

		if not player.blueprintKnown("distortionsphere2_tech") then
			player.giveBlueprint("distortionsphere2_tech")
		end
	end
end