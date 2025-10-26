-- \\ Services

local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")

-- \\ Modules

local config = require(script.Parent.Config) -- module for settings for inventory system

-- \\ Remote Events

local updateUiEvent = replicatedStorage.InventorySystem.RemoteEvents.updateUi
local updateStackNumberEvent = replicatedStorage.InventorySystem.RemoteEvents.updateStackNumber

-- \\ Variables

local playerInventoryManager = {} -- module table
local hotBar = {} -- hotBar = {[player] = [1] = value, [2] = value} etc etc

-- \\ Helper Functions

local function countKeys(player)
	local i = 0
	for _ in pairs(hotBar[player] or {}) do -- resort to an empty table if hotbar[player] is nil to avoid an error
		i += 1 -- count the amount of instances in the dictionary as #hotbar[player] doesnt work
	end
	
	return i -- return the amount of keys
end

local function checkForItem(player, item)
	for slot, data in pairs(hotBar[player] or {}) do -- loop through the players hotbar
		if data.Name == item.Name and data.Stack < config.maxStackAmount then -- if its the same item and the stack has space
			return false, slot -- return the stack position in the hotbar
		end
	end
end

local function getNextAvailableSlot(player)
	if not hotBar[player] then -- handle edge case of nil hotbar[player]
		return 1 -- return the first slot
	end
	
	for i = 1, config.hotbarSlotsAmount do
		if not hotBar[player][i] then -- if the slot is empty
			return i -- return the slot number
		end
	end
end

local function getItemData(player, slotNumber)
	if hotBar[player] and hotBar[player][slotNumber] then
		return hotBar[player][slotNumber] -- return the item data
	end
end

-- \\ Functions

function playerInventoryManager.addItem(player, item)	
	if not item then return end
	
	local full, slot =  playerInventoryManager.isFull(player, item)
	if full then 
		warn("Inventory is full!")
		return 
	end
	
	if not slot then
		slot = getNextAvailableSlot(player) -- get the next available slot
	end
	
	if not slot then return end -- if slot is still nil, exit
	
	local itemData = {
		Name = item.Name,
		Id = httpService:GenerateGUID(false), -- generate a unique id for the item
		Stackable = item:FindFirstChild("Stackable") and item:FindFirstChild("Stackable").Value, -- see if it can be stacked
		Stack = 1 -- init the stack
	}
	
	if itemData.Stackable then
		local slotItemData = getItemData(player, slot) -- get the item data from the slot
		
		if not slotItemData then
			hotBar[player][slot] = itemData 
			updateUiEvent:FireClient(player, slot, item.Name)
			updateStackNumberEvent:FireClient(player, slot, itemData.Stack)
		else
			slotItemData.Stack += 1
			updateStackNumberEvent:FireClient(player, slot, slotItemData.Stack)
		end
		
	else
		hotBar[player][slot] = itemData -- add item to the next available slot
		updateUiEvent:FireClient(player, slot, item.Name) -- fire remote event to update client inventory
	end
	
	return true -- return true if item was added successfully
end

function playerInventoryManager.removeItem(player, slotNumber)
	local slot = hotBar[player][slotNumber] -- get the item data from the slot
	if not slot then return false end -- handle edge case of that slot not having an item to start with

	if hotBar[player][slotNumber].Stack and hotBar[player][slotNumber].Stack > 1 then
		hotBar[player][slotNumber].Stack -= 1 -- decrease the stack by 1
		updateStackNumberEvent:FireClient(player, slotNumber, hotBar[player][slotNumber].Stack) -- update the ui
	else
		updateUiEvent:FireClient(player, slotNumber, "") -- fire remote event to update client inventory
		updateStackNumberEvent:FireClient(player, slotNumber, 0) -- update the ui
		hotBar[player][slotNumber] = nil -- delete slot data
	end

	return true -- successfully removed item
end

function playerInventoryManager.updateSlot(player, slotNumber, newItemData)	
	if (slotNumber < 1) or (slotNumber > config.hotbarSlotsAmount) then -- ensure the number is valid
		warn("Not a valid number!")
		return 
	end 
	if not newItemData then  -- ensure we have item data to add
		warn("No item data passed!")
		return 
	end
	
	if not hotBar[player] then 
		hotBar[player] = {}  -- ensure we have a player hotbar to write to
	end
	
	hotBar[player][slotNumber] = newItemData -- set the new item data
	updateUiEvent:FireClient(player, slotNumber, newItemData.Name) -- update the ui
	updateStackNumberEvent:FireClient(player, slotNumber, newItemData.Stack or 0)
end

function playerInventoryManager.swapItems(player, slotNumber1, slotNumber2)
	local data1 = hotBar[player][slotNumber1] -- get the data for the first slot
	local data2 = hotBar[player][slotNumber2] -- get the data for the second slot
	
	hotBar[player][slotNumber1], hotBar[player][slotNumber2] = data2, data1 -- swap the data
	
	for _, slotNumber in ipairs({slotNumber1, slotNumber2}) do
		updateUiEvent:FireClient(player, slotNumber, (hotBar[player][slotNumber] and hotBar[player][slotNumber].Name) or "") -- update the ui and ensure there's no error by falling back to an empty string
	end
	
	return true -- successful swap
end

function playerInventoryManager.isFull(player, item)
	local stackable = item:FindFirstChild("Stackable") and item.Stackable.Value

	if stackable then
		return checkForItem(player, item)
	end

	local usedSlotCount = countKeys(player)
	return usedSlotCount >= config.hotbarSlotsAmount, nil
end

function playerInventoryManager.getItems(player)
	return hotBar[player] or {} -- return the players hotbar
end

function playerInventoryManager.initPlayerHotbar(player)
	hotBar[player] = {} -- init a new table for the player which will store their hotbar
end

function playerInventoryManager.removePlayerHotbar(player)
	hotBar[player] = nil -- remove the hotbar from the table
end

return playerInventoryManager
