-- \\ Services 

local replicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Modules

local itemPickupHandler = require(script.ItemPickupHandler)
local playerInventoryManager = require(script.PlayerInventoryManager)
local inventoryDatastoreManager = require(script.InventoryDatastoreManager)
local equipmentManager = require(script.EquipmentManager)
local config = require(script.Config)

-- \\ Remote Events

local manageItemEquipmentEvent = replicatedStorage.InventorySystem.RemoteEvents.manageItemEquipment

-- \\ Variables

local equipCooldown = {}

-- \\ Init

itemPickupHandler.initItemFolder()

-- \\ Helper Functions

function manageItemEquipmentCooldowns(player)
	if equipCooldown[player] and (tick() - equipCooldown[player] < config.equipCooldownTime) then
		return false -- not ok to carry on; do this to avoid exploiters spamming our remote event or people spam equipping/unequipping
	end
	equipCooldown[player] = tick() -- get current time
	return true -- ok to carry on
end

-- \\ Functions

function manageItemEquipment(player, slotNumber)
	local ok = manageItemEquipmentCooldowns(player) -- manage cooldowns
	if not ok then
		warn("Ratelimited! Spam equipping/unequipping for " .. player.Name)
		return
	end
	
	if slotNumber and slotNumber == "drop" then -- detect for drop
		equipmentManager.dropItem(player)
		return
	elseif slotNumber and slotNumber == "use" then -- detect for item use
		equipmentManager.useItem(player)
		return
	end
	
	if typeof(slotNumber) ~= "number" then -- ensure slot number is a number
		warn("slotNumber is not a number!")
		return 
	end 
	
	if (slotNumber < 1) or (slotNumber > config.hotbarSlotsAmount) then  -- ensure we have a valid slot number
		warn("Slot number is not in the correct range!")
		return
	end 
	
	equipmentManager.toggle(player, slotNumber) -- toggle item equipped/unequipped
end

-- \\ Connections

game.Players.PlayerAdded:Connect(function(player) -- player joins
	player.CharacterAdded:Connect(function()
		task.wait(0.5) -- wait a small delay so the players ui loads
		
		local hotbar = playerInventoryManager.getItems(player) -- get the players hotbar and items
		if not hotbar or hotbar == {} then -- ensure the player has a hotbar
			warn("No hotbar, can't reload!")
			return
		end
		
		for slot, itemData in pairs(hotbar) do -- loop through the items in the players hotbar
			playerInventoryManager.updateSlot(player, slot, itemData) -- update the ui slots to match their item
		end
	end)
	
	inventoryDatastoreManager.loadInventory(player) -- load the players datastore
end)

game.Players.PlayerRemoving:Connect(function(player) -- player leaves
	inventoryDatastoreManager.saveInventory(player)
	playerInventoryManager.removePlayerHotbar(player) -- cleanup
	equipmentManager.cleanup(player) -- cleanup
end)

manageItemEquipmentEvent.OnServerEvent:Connect(manageItemEquipment)




