bee_transmogrifier_fuInit = init

function init()
	bee_transmogrifier_fuInit()

	-- if "genetic aberration" is researched, give the bee transmogrifier recipe
	if isResearched("frackinuniversemadness", "GS2") then
		if not player.blueprintKnown("bee_transmogrifier") then
			player.giveBlueprint("bee_transmogrifier")
		end
	end
end