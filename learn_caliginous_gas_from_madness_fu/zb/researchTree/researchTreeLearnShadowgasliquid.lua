learn_caliginous_gas_from_madness_fuInit = init

function init()
	learn_caliginous_gas_from_madness_fuInit()

	-- if Dark Matter is researched, give the Caliginous Gas recipe
	if isResearched("frackinuniversemadness", "CS2") then
		if not player.blueprintKnown("shadowgasliquid") then
			player.giveBlueprint("shadowgasliquid")
		end
	end
end