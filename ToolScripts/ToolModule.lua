-- \\ Services

local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

-- \\ Modules

local toolConfig = require(script.Config)
local inventoryConfig = require(game.ServerScriptService.InventoryScripts.InventoryManager.Config)
local equipmentManager = require(game.ServerScriptService.InventoryScripts.InventoryManager.EquipmentManager)

-- \\ Remote Events

local playSoundEvent = replicatedStorage.InventorySystem.RemoteEvents.playSound

-- \\ Variables

local toolModule = {}
local debounce = {}

-- \\ Helper Functions

local function editTreeHealthUi(tree)
	local healthUi = tree:FindFirstChild("HealthUi") -- get the health ui
	if not healthUi then -- if there isnt one already in the tree, make a new one and parent it to the tree
		healthUi = replicatedStorage.InventorySystem.UiAssets:FindFirstChild("HealthUi"):Clone()
		healthUi.Parent = tree
	end

	-- get variables for instances in the ui
	local healthFrame = healthUi and healthUi:FindFirstChild("HealthFrame")
	local healthSlider = healthFrame and healthFrame:FindFirstChild("HealthSlider")
	local healthText = healthFrame and healthFrame:FindFirstChild("HealthLabel")

	if not healthSlider or not healthText then  -- ensure they exist
		warn("Couldn't find health slider and/or health text!")
		healthUi:Destroy()
		return
	end

	local healthValue = tree:GetAttribute("Health") -- get the trees health
	local startingHealthValue = tree:GetAttribute("StartingHealth") -- get the trees starting health

	local goalSize = UDim2.fromScale(healthValue / startingHealthValue, healthSlider.Size.Y.Scale) -- get the new goal size
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = tweenService:Create(healthSlider, tweenInfo, { Size = goalSize }) -- create the tween
	tween:Play()

	healthText.Text = healthValue .. "/" .. startingHealthValue -- set the new text
end

local function damageTree(tree)
	local startingHealth = tree:GetAttribute("StartingHealth") -- get the trees starting health
	if not startingHealth then -- if the tree has no starting health, give it the default starting health of 0
		tree:SetAttribute("StartingHealth", 100)
		startingHealth = 100
	end

	if tree:GetAttribute("Health") then -- check if it already has health
		tree:SetAttribute("Health", math.max(0, tree:GetAttribute("Health") - toolConfig.damage)) -- if it does, decrease it by damage
	else
		tree:SetAttribute("Health", math.max(0, tree:GetAttribute("StartingHealth") - toolConfig.damage)) -- if it doesnt, set it to the starting health - damage
	end
end

local function destroyTree(tree)
	local dropsFolder = tree:FindFirstChild("Drops") -- find the folder which tells the program what the tree drops
	local dropData = {} -- init the drop data dict
	
	for _, drop in ipairs(dropsFolder:GetChildren()) do
		dropData[drop.Name] = drop.Value -- get each thing the tre will drop and add it to the dictionary
	end
	
	local treeCFrame = tree:GetPivot() -- get the trees cframe
	
	tree:Destroy()
	
	for dropName, dropAmount in pairs(dropData) do
		local amount = math.random(1, dropAmount) -- ranomize the amount of drops you will get for each item, from 1 to the max amount
		for i = 1, amount do -- repeat the code below for the amount of drops
			local dropModel = replicatedStorage.InventorySystem.ItemTemplates:FindFirstChild(dropName) -- get a new drop model
			if not dropModel then continue end -- skip if it doesnt exist

			local newDropModel = dropModel:Clone()
			newDropModel.Parent = workspace.DroppedItems -- parent it to the dropped items folder so it can be picked up
			newDropModel:PivotTo(treeCFrame) -- set the drop model to the trees cframe
		end
	end
end

local function axeHitPart(player, hitPart)
	if debounce[player.UserId] then return end -- ensure the player isnt on cooldown
	debounce[player.UserId] = true -- start the cooldown so they cant spam swing
	
	task.delay(toolConfig.swingTime, function() -- wait for a short period and then remove the cooldown
		debounce[player.UserId] = nil
	end)

	if not hitPart or not hitPart.Parent then  -- ensure hitpart exists
		warn("Hitpart or hitpart's parent doesnt exist!")
		return 
	end

	local tree = hitPart.Parent
	if tree.Parent ~= toolConfig.treeFolder then  -- ensure the hitpart is a tree
		warn("Hit part is not a tree!")
		return
	end

	damageTree(tree) -- damage the tree
	editTreeHealthUi(tree) -- edit the ui of the tree
	
	if tree:GetAttribute("Health") == 0 then
		destroyTree(tree)
	end
end

-- \\ Functions

function toolModule.use(player, id)
	local character = player.Character
	local axe = character and character:FindFirstChild(id) -- get the players axe
	local blade = axe and axe:FindFirstChild("AxeBlade") -- get the blade of the axe
	if not blade then 
		warn("Couldn't find axe blade!")
	end
	
	local swingSound = script.Sounds.AxeSwingSound -- get the swing sound
	playSoundEvent:FireClient(player, swingSound) -- play the swing sound
	
	local hitConnection
	hitConnection = blade.Touched:Connect(function(hitPart)
		axeHitPart(player, hitPart) -- handle the hit
	end)
	
	local playingAnimations = equipmentManager.getPlayingAnimations(player) -- get all of the player's current tool animations
	
	if playingAnimations and playingAnimations[inventoryConfig.useAnimationName] then
		local animTrack = playingAnimations[inventoryConfig.useAnimationName] -- get the use animation track currently playing
		
		animTrack.Ended:Connect(function() -- once the animation has finished
			hitConnection:Disconnect() -- stop listening for a touch on the blade once the animation of using the tool has stopped playing
		end)
	else -- if there's no animation with the tool, fallback onto the swing time to stop listening for the blade to be hit
		task.wait(toolConfig.swingTime)
		hitConnection:Disconnect()
	end
end

return toolModule
