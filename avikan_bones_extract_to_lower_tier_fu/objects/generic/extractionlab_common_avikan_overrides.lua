getRecipes_extractionlab_common_avikan_overrides = getRecipes

function getRecipes()
	recipes = getRecipes_extractionlab_common_avikan_overrides()

	overrides = {
		monsterscales = "monsterbone",
		monsterclaws = "monsterscales",
		monsterplate = "monsterclaws",
		monsterspine = "monsterplate"
	}

	for rkey, recipe in ipairs(recipes) do
		for input, icount in pairs(recipe.inputs) do
			if (overrides[input] ~= nil) then
				recipes[rkey].outputs = {}
				recipes[rkey].outputs[overrides[input]] = {1,1,1}
			end
		end
	end

	return recipes
end