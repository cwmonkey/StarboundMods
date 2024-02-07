-- extractionlab_common.lua
-- require "/objects/generic/extractor_xeno_common.lua"

-- unit times for the extractor tech levels
function getTimer(techLevel)
	return ({ 0.75, 0.45, 0.1 })[techLevel]
end

-- Format:
--   inputs = list of item=quantity pairs
--   outputs = list of item=quantity pairs
--   timeScale = extraction time scaling value (default 1); may be a list as for quantity
--               e.g. { 1, 2, 4 } gives { 0.75 * 1, 0.45 * 2, 0.1 * 4 } = { 0.75, 0.9, 0.4 }, but generally a single value should be used
--   reversible = true if the conversion can be reversed
--
--   Each quantity is either a single number or a table containing a value for each extractor tech level
--   Order is basic (1), advanced (2), quantum (3)
--
--   Listing order is no guarantee of checking order
--   No checks are made for multi-input recipes being overridden by single-input recipesa
function getRecipes()
	return root.assetJson('/objects/generic/extractionlab_recipes.config')
end


-- extractor_xeno_common.lua
require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local recipes

function init()
	powered = false

	-- Player interaction
	playerUsing = nil
	defaultDelta=config.getParameter("scriptDelta")
	message.setHandler("paneOpened", paneOpened)
	message.setHandler("paneClosed", paneClosed)
	-- /Player interaction

	self.mintick = config.getParameter("fu_mintick", 1)
	storage.timer = storage.timer or self.mintick
	storage.crafting = storage.crafting or false

	self.inputSlot = config.getParameter("inputSlot",3)
	self.outputSlots={}
	for i=0,self.inputSlot-1 do
		table.insert(self.outputSlots,i)
	end
	self.inputSlot = config.getParameter("inputSlot",1)
	self.techLevel = config.getParameter("fu_stationTechLevel", 1)

	storage.activeConsumption = storage.activeConsumption or false
	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,storage.activeConsumption)
	end

	recipes = getRecipes()

	-- generate reversed recipes here to avoid complicating the other code
	local reversed = {}
	for _, recipe in pairs(recipes) do
		if recipe.reversible then
			recipe.reversible = nil -- unmark it :-)
			table.insert(reversed, { inputs = recipe.outputs, outputs = recipe.inputs, timeScale = recipe.timeScale })
		end
	end
	for _, recipe in pairs(reversed) do
		table.insert(recipes, recipe)
	end
end

function techlevelMap(v)
	-- if the input is a table, do a lookup using the extractor tech level
	if type(v) == "table" then return v[self.techLevel] end
	return v
end

function getInputContents()
	local id = entity.id()
	local contents = {}
	for i = 0, self.inputSlot-1 do
		local stack = world.containerItemAt(id, i)
		if stack then
			contents[stack.name] = (contents[stack.name] or 0) + stack.count
		end
	end
	return contents
end

function map(list, func)
	local res = {}
	for k,v in pairs(list) do
		res[k] = func(v)
	end
	return res
end

function filter(list, func)
	return map(list, function(e) return func(e) and e or nil end)
end

function getValidRecipes(query)
	local function subset(inputs)
		if next(query) == nil then return false end
		if inputs == query then return true end
		local validRecipe = false
		for k, _ in pairs(inputs) do
			local required = techlevelMap(inputs[k])
			if required then
				validRecipe = true
				if required > (query[k] or 0) then return false end
			end
		end
		return validRecipe
	end

	return filter(recipes, function(l) return subset(l.inputs) end)
end

function update(dt)

	if playerUsing then
		if not self.mintick then init() end
		if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
			transferUtilDeltaTime=0
			transferUtil.loadSelfContainer()
		else
			transferUtilDeltaTime=transferUtilDeltaTime+dt
		end

		storage.timer = storage.timer - dt
		if storage.timer <= 0 then
			if storage.output then
				for k,v in pairs(storage.output) do
					fu_sendOrStoreItems(0, {name = k, count = techlevelMap(v)},self.outputSlots, true)
				end
				storage.output = nil
				storage.inputs = nil
				storage.timer = self.mintick --reset timer to a safe minimum
			else
				if not startCrafting(getInputContents()) then
					--set timeout and indicate not crafting if there were no recipes
					animator.setAnimationState("samplingarrayanim", "idle")
					storage.timer = self.mintick
					storage.activeConsumption = false
					if object.outputNodeCount() > 0 then
						object.setOutputNodeLevel(0,storage.activeConsumption)
					end
				end
			end
		end
	else
		animator.setAnimationState("samplingarrayanim", "idle")
		script.setUpdateDelta(-1)
	end
end

function findRecipe(input)
	local result=getValidRecipes(input)
	local listSize=util.tableSize(result)
	if listSize==1 then
		_,v = next(result)
		return v
	elseif listSize > 1 then
		local tempResult=false
		for _,resEntry in pairs(result) do
			if not tempResult then
				tempResult=resEntry
			else
				--sb.logInfo("%s",resEntry)
				if not resEntry.inputs then sb.logInfo("extractor error: no inputs: %s",result) return false end
				for resEntryInputItem,resEntryItemCount in pairs(resEntry.inputs) do
					if tempResult.inputs[resEntryInputItem] < resEntryItemCount then
						tempResult=resEntry
					end
				end
			end
		end
		return tempResult
	end
end

function startCrafting(inputs)
	for k,v in pairs(inputs) do
		local t={}
		t[k]=v
		local recipe=findRecipe(t)
		if recipe then
			if doCrafting(recipe) then
				return true
			end
		end
	end

	return false
end

function doCrafting(result)
	if result == nil then
		return false
	else
		--_, result = next(result)
		storage.inputs={}
		for itemName, quantities in pairs(result.inputs) do
			-- if we ever do multiple inputs, FIXME undo partial consumption on failure
			local itemData={item = itemName , count = techlevelMap(quantities)}
			if not (world.containerAvailable(entity.id(),{item = itemName}) >= techlevelMap(quantities) and (not powered or power.consume(config.getParameter('isn_requiredPower'))) and world.containerConsume(entity.id(), itemData)) then
				for _,v in pairs(storage.inputs) do
					for i=0,world.containerSize(entity.id())-1 do
						if v then
							v=world.containerPutItemsAt(entity.id(),v,i)
						else
							break
						end
					end
				end
				storage.inputs={}
				return false
			end
			table.insert(storage.inputs,itemData)
		end

		storage.timerMod = config.getParameter("fu_timerMod")
		storage.timer = ((techlevelMap(result.timeScale) or 1) * getTimer(self.techLevel)) + storage.timerMod
		storage.output = result.outputs
		animator.setAnimationState("samplingarrayanim", "working")

		storage.activeConsumption = true
		if object.outputNodeCount() > 0 then
			object.setOutputNodeLevel(0,storage.activeConsumption)
		end
		return true
	end
end

function die()
	if storage.inputs and #storage.inputs>0 then
		for _,v in pairs(storage.inputs) do
			world.spawnItem(v,entity.position())
		end
	end
end

-- beeExaminer.lua
function paneOpened()
	script.setUpdateDelta(defaultDelta)
	playerUsing = true

	-- sb.logInfo("---WM-------- storage.activeConsumption: %s", storage.activeConsumption)
	if storage.activeConsumption then
		if animator.animationState("samplingarrayanim") == "idle" then
			animator.setAnimationState("samplingarrayanim", "working")
		end
	end
end

function paneClosed()
	playerUsing = nil
end

