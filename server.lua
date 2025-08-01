local function GetRandItemFromTable(table)
	debugPrint("^5Debug^7: ^2Picking random item from table^7")
	::start::
	local randNum = math.random(1, 100)
	local items = {}
	for _, item in ipairs(table) do
		if randNum <= tonumber(item.rarity) then
			items[#items+1] = item.item
		end
	end
	if #items == 0 then
		goto start
	end
	local rand = math.random(1, #items)
	local selectedItem = items[rand]
	debugPrint("^5Debug^7: ^2Selected item ^7'^3"..selectedItem.."^7' - ^2rand^7: "..rand.." ^2length^7: "..#items)
	return selectedItem
end

RegisterServerEvent(getScript()..":Reward", function(data)
	local src = source
	local amount = 1

	if data.mine then

		local amount = GetTiming(Config.PoolAmounts.Mining.AmountPerSuccess)
		
		-- Check if setReward is a table (list) or a single item
		if type(data.setReward) == "table" then
			-- Handle multiple rewards
			local carryCheckTable = {}
			for _, rewardData in pairs(data.setReward) do
				local itemName = rewardData.item
				local itemAmount = rewardData.amount or amount
				carryCheckTable[itemName] = itemAmount
			end
			
			local carryCheck = canCarry(carryCheckTable, src)
			local canCarryAll = true
			
			-- Check if player can carry all items
			for itemName, _ in pairs(carryCheckTable) do
				if not carryCheck[itemName] then
					canCarryAll = false
					break
				end
			end
			
			if canCarryAll then
				-- Give all items
				for _, rewardData in pairs(data.setReward) do
					local itemName = rewardData.item
					local itemAmount = rewardData.amount or amount
					addItem(itemName, itemAmount, nil, src)
				end
			else
				triggerNotify(nil, locale("error", "full"), "error", src)
			end
		else
			-- Handle single reward (original logic)
			local carryCheck = canCarry({ [data.setReward] = amount }, src)
			
			if carryCheck[data.setReward] then
				addItem(data.setReward, amount, nil, src)
			else
				triggerNotify(nil, locale("error", "full"), "error", src)
			end
		end

	elseif data.crack then

		local selectedItem = GetRandItemFromTable(Config.CrackPool)
		amount = GetTiming(Config.PoolAmounts.Cracking.AmountPerSuccess)

		local canCarryCheck = canCarry({ [selectedItem] = amount }, src)

		if selectedItem and canCarryCheck[selectedItem] then
			removeItem("stone", data.cost, src)
			addItem(selectedItem, amount, nil, src)
		else
			triggerNotify(nil, locale("error", "full"), "error", src)
		end

	elseif data.wash then
		local rewards = {}

		-- Step 1: Determine all reward items
		for i = 1, GetTiming(Config.PoolAmounts.Washing.Successes) do
			local selectedItem = GetRandItemFromTable(Config.WashPool)
			local amount = GetTiming(Config.PoolAmounts.Washing.AmountPerSuccess)

			if selectedItem then
				rewards[selectedItem] = (rewards[selectedItem] or 0) + amount
			end
		end

		-- Step 2: Check if the player can carry all rewards
		local canCarryCheck = canCarry(rewards, src)

		local canCarryAll = true
		for item, _ in pairs(rewards) do
			if not canCarryCheck[item] then
				canCarryAll = false
				break
			end
		end

		-- Step 3: If they can carry, remove and reward. If not, notify.
		if canCarryAll then
			removeItem("stone", data.cost, src)

			for item, amount in pairs(rewards) do
				addItem(item, amount, nil, src)
			end
		else
			triggerNotify(nil, locale("error", "full"), "error", src)
		end

	elseif data.pan then

		for i = 1, GetTiming(Config.PoolAmounts.Panning.Successes) do

			local selectedItem = GetRandItemFromTable(Config.PanPool)
			amount = GetTiming(Config.PoolAmounts.Panning.AmountPerSuccess)

			local canCarryCheck = canCarry({ [selectedItem] = amount }, src)

			if selectedItem and canCarryCheck[selectedItem] then
				addItem(selectedItem, amount, nil, src)
			else
				triggerNotify(nil, locale("error", "full"), "error", src)
			end
		end

	end
end)


onResourceStart(function()
	Wait(1000)
	registerShop("miningShop", Config.Items.label, Config.Items.items)
	for k in pairs(Selling) do
		if Selling[k].Items then
			for b in pairs(Selling[k].Items) do
				if not Items[b] then print("Selling: Missing Item from Items: '"..b.."'") end
			end
		else
			for l in pairs(Selling[k]) do
				if l ~= "Header" then
					for b in pairs(Selling[k][l].Items) do
						if not Items[b] then print("Selling: Missing Item from Items: '"..b.."'") end
					end
				end
			end
		end
	end
	for i = 1, #Config.CrackPool do if not Items[Config.CrackPool[i].item] then print("CrackPool: Missing Item from Items: '"..Config.CrackPool[i].item.."'") end end
	for i = 1, #Config.WashPool do if not Items[Config.WashPool[i].item] then print("WashPool: Missing Item from Items: '"..Config.WashPool[i].item.."'") end end
	for i = 1, #Config.PanPool do if not Items[Config.PanPool[i].item] then print("PanPool: Missing Item from Items: '"..Config.PanPool[i].item.."'") end end
	for i = 1, #Config.Items.items do if not Items[Config.Items.items[i].name] then print("Shop: Missing Item from Items: '"..Config.Items.items[i].name.."'") end end
	local itemcheck = {}
	for _, v in pairs(Crafting) do
		if type(v) == "table" then
			for _, b in pairs(v.Recipes) do
				for k, l in pairs(b) do
					if k ~= "amount" then
						itemcheck[k] = {}
						for j in pairs(l) do
							itemcheck[j] = {}
						end
					end
				end
			end
		end
	end
	for k in pairs(itemcheck) do
		if not Items[k] then print("Crafting recipe couldn't find item '"..k.."' in the shared") end
	end
end, true)