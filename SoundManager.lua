-- \\ Services

local soundService = game:GetService("SoundService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Remote Events

local playSoundEvent = replicatedStorage.InventorySystem.RemoteEvents.playSound

-- \\ Functions

local function playSound(sound)
	local newSound = sound:Clone() -- duplicate the sound so multiple can play at once if needed
	newSound.Parent = soundService
	newSound:Play() -- play the sound

	task.delay(newSound.TimeLength, function() -- create a new thread and delete the sound after a set period
		newSound:Destroy()
	end)
end

playSoundEvent.OnClientEvent:Connect(playSound)
