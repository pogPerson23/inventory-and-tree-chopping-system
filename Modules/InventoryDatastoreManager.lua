-- \\ Services

local datastoreService = game:GetService("DataStoreService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Modules

local playerInventoryManager = require(script.Parent.PlayerInventoryManager)
local equipmentManager = require(script.Parent.EquipmentManager)

-- \\ Variables

local inventoryDatastore = datastoreService:GetDataStore("InventoryDatastore") -- datastore for inventory 

local inventoryDatastoreManager = {} -- module table

-- \\ Functions

function inventoryDatastoreManager.saveInventory(player)
	local hotbar = playerInventoryManager.getItems(player) -- gets the player's itemData in inventory
	
	local success, err -- init the variables
	local i = 0 -- try counter
	repeat
		i += 1 -- increment the amount of attempts
		success, err = pcall(function()
			inventoryDatastore:SetAsync(player.UserId, hotbar) -- attempt to save the data
		end)
		if not success then -- if not a success, wait for a short period to avoid ratelimits
			task.wait(0.3)
		end
	until success or i >= 3 -- break out of the loop if the data was saved or the max amount of attempts was reached
	
	if not success then
		warn("Failed to save data for " .. player.Name .. " Error: " .. err) -- print to console that the data wasn't saved
	else
		print("Successfully saved data for " .. player.Name) -- print to console that the data was saved sucessfully
	end
end

function inventoryDatastoreManager.loadInventory(player)
	playerInventoryManager.initPlayerHotbar(player)
	
	local success, hotbarData -- init the variables
	local i = 0 -- init retry counter
	repeat
		i += 1 -- increment the counter
		success, hotbarData = pcall(function()
			return inventoryDatastore:GetAsync(player.UserId) -- attempt to fetch the players data
		end)
		
		if not success then
			task.wait(0.3) -- wait a short period to avoid ratelimits if not successful in fetching data
		end
	until success or i >= 3 -- break out of repeat loop if successfully got data or reached max amount of attempts
	
	if not success then
		warn("Failed to load data for " .. player.Name)
		player:Kick("Failed to load data; kicked to avoid dataloss. Please try to rejoin.") -- kick the player to avoid overwriting data
		return
	end
	
	if not hotbarData then  -- skip loading the data if there's nothign to load
		print("No data to load!")
		return 
	end
	
	for slotNumber, data in pairs(hotbarData) do
		playerInventoryManager.updateSlot(player, slotNumber, data) -- update the players inventory slots with the loaded data
		local item = replicatedStorage.InventorySystem.ItemTemplates:FindFirstChild(data.Name)
		if item then
			equipmentManager.preloadAnimations(player, item)
		end
	end
	
	print("Sucessfully loaded data for " .. player.Name)
end

return inventoryDatastoreManager
