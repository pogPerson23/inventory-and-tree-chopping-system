-- \\ Services

local contentProvider = game:GetService("ContentProvider")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Remote Events

local preloadAnimationsEvent = replicatedStorage.InventorySystem.RemoteEvents.preloadAnimations

-- \\ Functions

local function preloadAnimation(animation)
	contentProvider:PreloadAsync({animation}) -- preload the animation to avoid delay when the player equips/uses the item
end

-- \\ Connections

preloadAnimationsEvent.OnClientEvent:Connect(preloadAnimation)
