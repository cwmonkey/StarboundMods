learn_precursor_data_key_from_madness_fuInit = init

function init()
	learn_precursor_data_key_from_madness_fuInit()

	-- if Dark Matter is researched, give the Caliginous Gas recipe
	if isResearched("frackinuniversemadness", "WS4") then
		if not player.blueprintKnown("sciencebrochure2") then
			player.giveBlueprint("sciencebrochure2")
		end
	end
end