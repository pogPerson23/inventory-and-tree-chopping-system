-- \\ Services

local replicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Modules

local config = require(script.Parent.Config)
local playerInventoryManager = require(script.Parent.PlayerInventoryManager)

-- \\ Remote Events

local toggleSlotBorderUiEvent = replicatedStorage.InventorySystem.RemoteEvents.toggleSlotBorderUi
local preloadAnimationsEvent = replicatedStorage.InventorySystem.RemoteEvents.preloadAnimations

-- \\ Variables

local equipmentManager = {} -- module table
local playerEquippedItems = {} -- player state table
local playingAnimations = {} -- player state table

-- \\ Helper Functions

local function stopAnim(player, animName)
	if playingAnimations[player.UserId] and playingAnimations[player.UserId][animName] then -- ensure the track exists
		playingAnimations[player.UserId][animName]:Stop() -- stop the animation
		playingAnimations[player.UserId][animName] = nil -- remove the animation
	end
end

local function playAnimation(player, character, animation, animationName)
	if not playingAnimations[player.UserId] then
		playingAnimations[player.UserId] = {} -- init the animations dict if there isnt one already
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")
	if not animator then return end

	local animationTrack = animator:LoadAnimation(animation) -- load the animation
	animationTrack:Play() -- play the animation
	playingAnimations[player.UserId][animationName] = animationTrack -- save the animation

	return animationTrack
end

local function disableCollisions(item)
	for _, part in item:GetChildren() do -- get the children of the item
		if part:IsA("BasePart") then -- ensure it is a part
			part.CanCollide = false -- make it so you cant collide with them
		end
	end
end

local function toolModuleUseFunction(player, itemName, itemId)
	local itemModulesFolder = replicatedStorage.InventorySystem.ItemModules
	local itemFolder = itemModulesFolder and itemModulesFolder:FindFirstChild(itemName)
	local toolModule = itemFolder and require(itemFolder:FindFirstChild(config.toolModuleName)) -- get the tools function module
	if not toolModule then -- ensure it has one
		return
	end 
	
	local success, err = pcall(function() -- mitigate against erros
		toolModule.use(player, itemId) -- use the tool
	end)
	
	if not success then -- handle errors
		warn("Tool module has no function 'use'! Error: " .. err)
	end
end

local function createDroppedItem(player, itemName)
	local itemTemplate = replicatedStorage.InventorySystem.ItemTemplates:FindFirstChild(itemName) -- get the item for the dropped item
	if not itemTemplate then return end

	local droppedItem = itemTemplate:Clone() -- clone the template
	droppedItem.Parent = workspace.DroppedItems -- parent it to the dropped item folder so it can be picked up

	local handle = droppedItem:FindFirstChild("Handle") -- get the handle
	if not handle then return end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local lookVector = hrp.CFrame.LookVector -- get the players looking direction
	handle.CFrame = CFrame.new(hrp.Position + (lookVector * 2)) -- position the handle of the item 2 studs infront of the player in the direction they are facing
end

-- \\ Functions

local function equipItem(player, item, itemData, slotNumber)
	local character = player.Character
	if not character then 
		warn("No character")
		return 
	end
	
	item.Parent = character -- equip the item
	item.Name = itemData.Id -- uniquely name the part
	disableCollisions(item) -- disable its collisions
	
	if not playerEquippedItems[player.UserId] then
		playerEquippedItems[player.UserId] = {} -- ensure there is an equipped items dict to avoid errors
	end
	
	playerEquippedItems[player.UserId].Name = itemData.Name -- save the name 
	playerEquippedItems[player.UserId].itemId = itemData.Id -- save the equipped item
	playerEquippedItems[player.UserId].slotNumber = slotNumber -- save the slot number
	
	toggleSlotBorderUiEvent:FireClient(player, slotNumber)
	
	local equippedAnimation = item:FindFirstChild(config.equippedAnimationName) -- get the equip animation
	
	if equippedAnimation then
		playAnimation(player, character, equippedAnimation, config.equippedAnimationName)
	end
end

local function unequipItem(player)
	if not playerEquippedItems[player.UserId] then return end
	
	local itemName = playerEquippedItems[player.UserId].itemId
	if not itemName then return end -- ensure the player has an item equipped
	
	local character = player.Character
	if not character then return end
	
	local item = character:FindFirstChild(itemName)
	if not item then return end -- ensure the item exists
	
	item:Destroy() -- destroy the cloned equipped item
	toggleSlotBorderUiEvent:FireClient(player, playerEquippedItems[player.UserId].slotNumber) -- update the ui
	
	playerEquippedItems[player.UserId] = nil -- remove player equipped item from dictionary
	
	-- stop all animations
	stopAnim(player, config.equippedAnimationName)
	stopAnim(player, config.useAnimationName)
end

function equipmentManager.toggle(player, slotNumber)
	local itemData = playerInventoryManager.getItems(player)[slotNumber] -- check if slot has an item
	if not itemData then  -- slot has no item
		unequipItem(player) -- uneqip any equipped items
		warn("Player tried to equip empty slot; unequipping any equipped items.")
		return 
	end
	
	if playerEquippedItems[player.UserId] and playerEquippedItems[player.UserId].itemId == itemData.Id then -- player has this item equipped, so unequip
		unequipItem(player)
		return
	end
	
	local itemTemplate = replicatedStorage.InventorySystem.ItemTemplates:FindFirstChild(itemData.Name) -- try to get the item
	if not itemTemplate then -- no item template to create item from
		warn("No item template for " .. itemData.Name)
		return
	end
	
	local item = itemTemplate:Clone() -- replicate the template
	
	if not playerEquippedItems[player.UserId] then  -- player has nothing equipped
		equipItem(player, item, itemData, slotNumber)
	else -- player has something equipped already
		unequipItem(player) -- unequip current item
		equipItem(player, item, itemData, slotNumber) -- equip new item
	end
end

function equipmentManager.dropItem(player)
	if not playerEquippedItems[player.UserId] then
		warn("Can't drop item, nothing equipped!")
		return
	end

	local slotNumber = playerEquippedItems[player.UserId].slotNumber
	local itemName = playerEquippedItems[player.UserId].Name

	local itemData = playerInventoryManager.getItems(player)[slotNumber] -- get the slots data
	if not itemData then return end

	local isStack = itemData.Stack and itemData.Stack > 1 -- check if it is a valid stack

	unequipItem(player) -- unequip the item we are trying to drop
	playerInventoryManager.removeItem(player, slotNumber) -- delete it from the inventory

	if isStack then
		equipmentManager.toggle(player, slotNumber) -- equip the item again if it was a stack
	end

	createDroppedItem(player, itemName) -- create a new dropped item
end

function equipmentManager.useItem(player)
	if not playerEquippedItems[player.UserId] then -- ensure there's an equipped item
		warn("Can't use item, no item equipped!")
		return
	end
	
	if playingAnimations[player.UserId] and playingAnimations[player.UserId][config.useAnimationName] then -- make sure the tool isnt already being used
		warn("Animation still playing, can't use again!")
		return
	end
	
	local character = player.Character
	local item = character and character:FindFirstChild(playerEquippedItems[player.UserId].itemId) -- get the equipped item
	if not item then -- ensure the player has the item equipped
		warn("Can't find item to use!")
		return
	end
	
	local useAnimation = item:FindFirstChild(config.useAnimationName) -- get the use animation
	if not useAnimation then
		toolModuleUseFunction(player, playerEquippedItems[player.UserId].Name) -- trigger the use function in the tools functions module
		warn("No using animation")
		return 
	end
	
	local animTrack = playAnimation(player, character, useAnimation, config.useAnimationName) -- play the use animation
	if not animTrack then  -- ensure the animation track exists before trying to use it
		warn("Failed to load and play animation!")
	else
		animTrack.Ended:Connect(function() -- once the animation is finished 
			stopAnim(player, config.useAnimationName) -- clean up the use animation in dictionaries
		end)
	end
	
	toolModuleUseFunction(player, playerEquippedItems[player.UserId].Name, playerEquippedItems[player.UserId].itemId) -- trigger the tools module use function so the tool can work
end

function equipmentManager.preloadAnimations(player, item)
	-- get the animations
	local equippedAnimation = item:FindFirstChild(config.equippedAnimationName) 
	local useAnimation = item:FindFirstChild(config.useAnimationName)
	
	if equippedAnimation then -- make sure the animation exists
		preloadAnimationsEvent:FireClient(player, equippedAnimation) -- preload it to avoid delay when playing
	end
	
	if useAnimation then -- make sure the animation exists
		preloadAnimationsEvent:FireClient(player, useAnimation) -- preload it to avoid delay when playing
	end
end

function equipmentManager.getPlayingAnimations(player)
	return playingAnimations[player] -- return the players current playing animations
end

function equipmentManager.cleanup(player) -- get rid of unnecessary data in dictionaries
	playerEquippedItems[player.UserId] = nil
	playingAnimations[player.UserId] = nil
	print("Equipment Manager: Cleaned up data for " .. player.Name)
end

return equipmentManager
