-- \\ Modules

local playerInventoryManager = require(script.Parent.PlayerInventoryManager)
local equipmentManager = require(script.Parent.EquipmentManager)

-- \\ Variables

local itemPickupHandler = {} -- module table

local droppedItemsFolder = workspace.DroppedItems -- folder where dropped items are stored
local activeConnections = {} -- table for stored connections

-- \\ Functions

local function pickupItem(player, item)
	local success = playerInventoryManager.addItem(player, item) -- add the item to inventory
	
	if success then 
		equipmentManager.preloadAnimations(player, item) -- preload animations
		item:Destroy() -- delete item
	else
		warn("Failed to pickup item!")
	end
end

local function detectPickup(item)
	local clickDetector = item:FindFirstChild("ClickDetector") 
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector") -- ensure the player can click the dropped item
		clickDetector.Parent = item
	end
	
	local connection, cleanupConnection -- init connections
	
	connection = clickDetector.MouseClick:Connect(function(player)
		pickupItem(player, item)
	end)

	cleanupConnection = item.AncestryChanged:Connect(function()
		if not item:IsDescendantOf(game) then -- if the part has been destroyed
			connection:Disconnect() -- disconnect all connections to avoid memory leaks
			cleanupConnection:Disconnect()
			activeConnections[item] = nil
		end
	end)

	activeConnections[item] = {connection, cleanupConnection} -- init the connections in table
end

function itemPickupHandler.initItemFolder()
	for _, item in ipairs(droppedItemsFolder:GetChildren()) do -- setup click detection for already droppe items (if any)
		detectPickup(item)
	end

	droppedItemsFolder.ChildAdded:Connect(function(item) -- once a new item is added, setup click detection
		detectPickup(item)
	end)
end

return itemPickupHandler -- return the module
