require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require '/scripts/fupower.lua'

liquidwaterCountRequired = 50
psionicenergy2CountRequired = 20

function init()
	power.init()
	object.setInteractive(true)

	storage.waterInput = nil
	storage.enrichedInput = nil
	storage.neutoniumInput = nil
	storage.antineutoniumInput = nil

	storage.lasombriumInput = nil
	storage.telebriumInput = nil
	storage.zerchesiumInput = nil
	storage.triangliumInput = nil

	storage.effigiumInput = nil
	storage.pyreiteInput = nil
	storage.isogenInput = nil
	storage.densiniumInput = nil

	storage.currentinput = nil
	storage.currentoutput = nil
	-- storage.bonusoutputtable = nil
	storage.activeConsumption = false
	self.requiredPower=config.getParameter("isn_requiredPower", 1)

	self.timerInitial = config.getParameter ("fu_timer", 1)
	--script.setUpdateDelta(self.timerInitial*60.0)
	script.setUpdateDelta(1)
	self.effectiveRequiredPower=self.requiredPower*self.timerInitial

	--self.extraConsumptionChance = config.getParameter ("fu_extraConsumptionChance", 0)
	-- self.extraProductionChance = config.getParameter ("fu_extraProductionChance")
	self.itemList=config.getParameter("inputsToOutputs")
	-- self.bonusItemList=config.getParameter("bonusOutputs")
	self.timer = self.timerInitial
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	self.timer = (self.timer or self.timerInitial) - dt
	if self.timer <= 0 then
		self.timer = self.timerInitial
		local outputOre, outputType = getOutputOre()

	-- 	local checkNormal,checkBonus=oreCheck()
		local cSC=(outputOre and clearSlotCheck(storage.currentoutput)) or false
	-- 	--sb.logInfo("checkNormal=%s,cSC=%s,checkBonus=%s",checkNormal,cSC,checkBonus)
	-- 	if (checkNormal and cSC) or (checkBonus) then
		if outputOre and cSC then
			if (power.getTotalEnergy()>=self.effectiveRequiredPower) and world.containerConsume(entity.id(), {name = "liquidwater", count = liquidwaterCountRequired, data={}}) and world.containerConsume(entity.id(), {name = "solariumstar", count = 1, data={}}) and (world.containerConsume(entity.id(), {name = "enricheduranium", count = 1, data={}}) or world.containerConsume(entity.id(), {name = "enrichedplutonium", count = 1, data={}})) and power.consume(self.effectiveRequiredPower) then
				local activeState = "active"

				if outputType == "advanced" then
					world.containerConsume(entity.id(), {name = "psionicenergy2", count = psionicenergy2CountRequired, data={}})
					world.containerConsume(entity.id(), {name = "xithricitecrystal", count = 1, data={}})
					activeState = "activex"
				end

				animator.setAnimationState("shcState", activeState)
				object.setOutputNodeLevel(0,true)
				storage.activeConsumption = true
				local outputBarsCount=1

				-- TODO: these ifs aren't needed
				if type(storage.currentoutput)=="string" then--normal output is always a single item, not a table
					if outputBarsCount>0 then
						fu_sendOrStoreItems(0, {name = storage.currentoutput, count = outputBarsCount, data = {}}, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, true)
					end
				end
			else
				storage.activeConsumption = false
				animator.setAnimationState("shcState", "idle")
				object.setOutputNodeLevel(0,false)
			end
		else
			animator.setAnimationState("shcState", "idle")
			object.setOutputNodeLevel(0,false)
		end
	end
	power.update(dt)
end

function getOutputOre()
	-- Simple reagents (consumable)
	local waterItem = world.containerItemAt(entity.id(),0)
	if not waterItem or waterItem.name ~= "liquidwater" or waterItem.count < liquidwaterCountRequired then
		-- if waterItem then sb.logInfo("Position 0 contains no water, or not enough: %s", waterItem) end
		return false
	end

	-- .name = enricheduranium || enrichedplutonium
	local enrichedItem = world.containerItemAt(entity.id(),1)
	if not enrichedItem or enrichedItem.name ~= "enricheduranium" and enrichedItem.name ~= "enrichedplutonium" then
		-- if enrichedItem then sb.logInfo("Position 0 contains no enriched rod: %s", enrichedItem) end
		return false
	end

	-- Simple outputs
	for key, value in pairs(self.itemList.simple) do
		local item = world.containerItemAt(entity.id(),value.slot)
		if item and item.name == "solariumstar" then
			storage.currentoutput = value.name
			return storage.currentoutput, "simple"
		end
	end

	-- Advanced reagents
	local xithricitecrystalItem = world.containerItemAt(entity.id(),6)
	if not xithricitecrystalItem or xithricitecrystalItem.name ~= "xithricitecrystal" then
		-- if neutroniumItem then sb.logInfo("Position 6 contains no neutronium: %s", neutroniumItem) end
		return false
	end

	local psionicenergy2Item = world.containerItemAt(entity.id(),7)
	if not psionicenergy2Item or psionicenergy2Item.name ~= "psionicenergy2" or psionicenergy2Item.count < psionicenergy2CountRequired then
		-- if antineutroniumItem then sb.logInfo("Position 7 contains no antineutronium: %s", antineutroniumItem) end
		return false
	end

	-- Advanced outputs
	for key, value in pairs(self.itemList.advanced) do
		local item = world.containerItemAt(entity.id(),value.slot)
		if item and item.name == "solariumstar" then
			storage.currentoutput = value.name
			return storage.currentoutput, "advanced"
		end
	end

	-- no solarium found
	return false
end

function clearSlotCheck(checkname)
	if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
		return true
	else
		return false
	end
end
