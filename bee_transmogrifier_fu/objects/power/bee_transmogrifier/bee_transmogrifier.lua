require "/bees/genomeLibrary.lua"
require '/scripts/fupower.lua'

function init()
	debug = false

	if debug then sb.logInfo("DEBUG: Init") end

	power.init()
	object.setInteractive(true)

	storage.beeLarvaInput = nil
	storage.psionicenergyInput = nil
	storage.reagntInput = nil

	storage.currentinput = nil
	storage.currentoutput = nil

	storage.activeConsumption = false
	self.requiredPower=config.getParameter("isn_requiredPower", 1)

	self.timerInitial = config.getParameter ("fu_timer", 1)
	--script.setUpdateDelta(self.timerInitial*60.0)
	script.setUpdateDelta(1)
	self.effectiveRequiredPower=self.requiredPower*self.timerInitial

	self.timer = self.timerInitial

	-- Bee stuff
	beeData = root.assetJson("/bees/beeData.config")

	beeItemNameToStats = {}
	productionItemNamesToBeeSubTypes = {}

	for beeType, beeSubTypes in pairs(beeData.stats) do
		beeItemName = "bee_"..beeType.."_queen"
		if debug then sb.logInfo("DEBUG: Adding bee type: %s", beeItemName) end
		beeItemNameToStats[beeItemName] = {
			beeType = beeType,
			stats = value
		}

		for _, beeSubtypeInfo in ipairs(beeSubTypes) do
			for itemName, makeTime in pairs(beeSubtypeInfo.production) do
				if not productionItemNamesToBeeSubTypes[itemName] then
					productionItemNamesToBeeSubTypes[itemName] = {
						beeSubTypes = {},
						total = 0
					}
				end

				productionItemNamesToBeeSubTypes[itemName].total = productionItemNamesToBeeSubTypes[itemName].total + makeTime

				table.insert(productionItemNamesToBeeSubTypes[itemName].beeSubTypes, {
					beeType = beeType,
					beeSubType = beeSubtypeInfo.name,
					beeSubtypeInfo = beeSubtypeInfo,
					rate = makeTime
				})
			end
		end
	end
end

function update(dt)
	self.timer = (self.timer or self.timerInitial) - dt

	if self.timer <= 0 then
		self.timer = self.timerInitial

		local activeState = "idle"
		local slotsValid = false
		local beeItem = world.containerItemAt(entity.id(), 0)
		local reagentItem = world.containerItemAt(entity.id(), 1)

		-- if debug then sb.logInfo("DEBUG: checkSlots") end

		if not beeItem then
			if debug then sb.logInfo("Error: No bee item.") end
		elseif beeItemNameToStats[beeItem.name] == nil then
			if debug then sb.logInfo("Error: Invalid bee item. beeItem.name=%s",beeItem.name) end
		else
			slotsValid = true
			activeState = "hasbee"
		end

		if (slotsValid) then
			if not reagentItem then
				if debug then sb.logInfo("Error: No reagent item.") end
				slotsValid = false
			elseif productionItemNamesToBeeSubTypes[reagentItem.name] == nil then
				if debug then sb.logInfo("Error: Invalid reagent item. reagentItem.name=%s", reagentItem.name) end
				slotsValid = false
			end
		end

		if slotsValid then
			if debug then sb.logInfo("DEBUG: Slots valid.") end

			local hasPower = (power.getTotalEnergy() >= self.effectiveRequiredPower)
			local consumedReagent = false
			local consumedPower = false

			if (hasPower) then
				-- if debug then sb.logInfo("DEBUG: Has power.") end
				consumedReagent = world.containerConsume(entity.id(), {name = reagentItem.name, count = 1, data={}})
				-- consumedReagent = true
			else
				if debug then sb.logInfo("DEBUG: No power. power.getTotalEnergy(): %s, self.effectiveRequiredPower: %s", power.getTotalEnergy(), self.effectiveRequiredPower) end
			end

			if (consumedReagent) then
				-- if debug then sb.logInfo("DEBUG: Consumed reagent.") end
				consumedPower = power.consume(self.effectiveRequiredPower)
				-- consumedPower = true
			end

			if consumedPower then
				-- if debug then sb.logInfo("DEBUG: Consumed power.") end
				activeState = "active"

				local psionicenergyItem = world.containerItemAt(entity.id(), 2)

				local liklihood = .01
				local consumePsionicenergyItem = false

				if debug then sb.logInfo("DEBUG: Liklihood starting at %s%%", liklihood * 100) end

				-- Psionic Energy Modifier

				if (psionicenergyItem) then
					if (psionicenergyItem.name == "psionicenergy") then
						consumePsionicenergyItem = true
						liklihood = liklihood * 1.5
						if debug then sb.logInfo("DEBUG: Psi-1 Energy used, liklihood rises to %s%%", liklihood * 100) end
					elseif (psionicenergyItem.name == "psionicenergy2") then
						consumePsionicenergyItem = true
						liklihood = liklihood * 2.5
						if debug then sb.logInfo("DEBUG: Psi-2 Energy used, liklihood rises to %s%%", liklihood * 100) end
					elseif (psionicenergyItem.name == "psionicenergy3") then
						consumePsionicenergyItem = true
						liklihood = liklihood * 4
						if debug then sb.logInfo("DEBUG: Psi-3 Energy used, liklihood rises to %s%%", liklihood * 100) end
					elseif (psionicenergyItem.name == "psionicenergy4") then
						consumePsionicenergyItem = true
						liklihood = liklihood * 6
						if debug then sb.logInfo("DEBUG: Psi-4 Energy used, liklihood rises to %s%%", liklihood * 100) end
					else
						if debug then sb.logInfo("DEBUG: Not valid psi energy. psionicenergyItem.name: %s", psionicenergyItem.name) end
					end

					if consumePsionicenergyItem then
						world.containerConsume(entity.id(), {name = psionicenergyItem.name,count = 1, data={}})
					end
				end

				-- Select Random Bee Based on Reagent

				local targetBee = getWeightedRandomBeeFromReagent(reagentItem.name)

				if debug then sb.logInfo("DEBUG: Weighted random chose %s:%s", targetBee.beeType, targetBee.beeSubType) end

				beeStats = beeItemNameToStats[beeItem.name]
				targetBeeStats = beeItemNameToStats["bee_"..targetBee.beeType.."_queen"]

				-- Check rivalry status

				if beeData.rivals[targetBeeStats.beeType] == beeStats.beeType or beeData.rivals[beeStats.beeType] == targetBeeStats.beeType then
					liklihood = liklihood * .1
					if debug then sb.logInfo("DEBUG: Bees are rivals, liklihood reduced to %s%%", liklihood * 100) end
				end

				-- Check World Likeness

				worldLike = beeData.biomeLikeness[targetBee.beeType][world.type()]

				if (worldLike ~= nil) then
					if (worldLike == 0) then
						liklihood = liklihood * .1
						if debug then sb.logInfo("DEBUG: Current biome deadly to this bee, liklihood reduced to %s%%", liklihood * 100) end
					elseif (worldLike == 1) then
						liklihood = liklihood * .5
						if debug then sb.logInfo("DEBUG: Current biome disliked by this bee, liklihood reduced to %s%%", liklihood * 100) end
					elseif (worldLike == 2) then
						if debug then sb.logInfo("DEBUG: Current biome liked by this bee, liklihood stays at %s%%", liklihood * 100) end
					elseif (worldLike == 3) then
						liklihood = liklihood * 2
						if debug then sb.logInfo("DEBUG: Current biome loved by this bee, liklihood increased to %s%%", liklihood * 100) end
					end
				end

				-- Check Reagent Create Time (higher = more likely to make)

				if (targetBee.rate < 50) then
					liklihood = liklihood * .5;
					if debug then sb.logInfo("DEBUG: Quickly made material for this bee, liklihood reduced to %s%%", liklihood * 100) end
				elseif (targetBee.rate < 150) then
					liklihood = liklihood * .75;
					if debug then sb.logInfo("DEBUG: Somewhat quickly made material for this bee, liklihood reduced to %s%%", liklihood * 100) end
				elseif (targetBee.rate < 400) then
					if debug then sb.logInfo("DEBUG: Average speed material for this bee, liklihood stays at %s%%", liklihood * 100) end
				elseif (targetBee.rate < 600) then
					liklihood = liklihood * 1.5;
					if debug then sb.logInfo("DEBUG: Somewhat slowly made material for this bee, liklihood increased to %s%%", liklihood * 100) end
				elseif (targetBee.rate < 900) then
					liklihood = liklihood * 1.75;
					if debug then sb.logInfo("DEBUG: Slowly made material for this bee, liklihood increased to %s%%", liklihood * 100) end
				else
					liklihood = liklihood * 2;
					if debug then sb.logInfo("DEBUG: Very slowly made material for this bee, increased reduced to %s%%", liklihood * 100) end
				end

				animator.setAnimationState("bee_transmogrifierState", activeState)
				-- object.setOutputNodeLevel(0, true)
				-- storage.activeConsumption = true
				-- local outputBarsCount = 1

				local rand = math.random()

				if (liklihood >= rand) then
					if debug then sb.logInfo("DEBUG: Liklihood was %s, you rolled %s and made a bee!", liklihood, rand) end
					local genome = genelib.generateDefaultGenome(string.format("bee_%s_queen", targetBee.beeType));
					world.spawnMonster(string.format("bee_%s", targetBee.beeType), object.toAbsolutePosition({ 2, 3 }), { genome = genome, wild = true })
					world.containerConsume(entity.id(), {name = beeItem.name, count = 1, data={}})
				else
					if debug then sb.logInfo("DEBUG: Liklihood was %s, you rolled %s and did not make a bee.", liklihood, rand) end
				end

			else
				-- storage.activeConsumption = false
				animator.setAnimationState("bee_transmogrifierState", activeState)
				-- object.setOutputNodeLevel(0, false)
			end
		else
			animator.setAnimationState("bee_transmogrifierState", activeState)
			-- object.setOutputNodeLevel(0, false)
		end
	end

	power.update(dt)
end

function getWeightedRandomBeeFromReagent(reagentItemName)
	pool = productionItemNamesToBeeSubTypes[reagentItemName].beeSubTypes

	local poolsize = productionItemNamesToBeeSubTypes[reagentItemName].total

	-- if debug then sb.logInfo("DEBUG: poolsize is %s.", poolsize) end

	local selection = math.random(1, poolsize)

	-- if debug then sb.logInfo("DEBUG: selection is %s.", selection) end

	for _, v in ipairs(pool) do
		selection = selection - v.rate

		-- if debug then sb.logInfo("DEBUG: v.beeType is %s.", v.beeType) end

		if selection <= 0 then
			return v
		end
	end
end