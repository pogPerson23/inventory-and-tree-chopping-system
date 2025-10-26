-- \\ Services

local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

-- \\ Remote Events

local manageItemEquipmentEvent = replicatedStorage.InventorySystem.RemoteEvents.manageItemEquipment

-- \\ Variables

local inputs = { -- table for all valid inputs
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight]= 8,
	[Enum.KeyCode.Nine] = 9
}

local player = players.LocalPlayer
local playerUi = player.PlayerGui

local inventoryUi = playerUi:WaitForChild("Inventory")
local hotbar = inventoryUi:WaitForChild("Hotbar")

-- \\ Functions

local function setupClickDetection()
	for _, button in hotbar:GetChildren() do -- get all the buttons in the hotbar
		if not button:IsA("TextButton") then return end -- ensure it is a button
		
		button.MouseButton1Click:Connect(function()
			local slotNumber = string.match(button.Name, "%d") -- get the number out of the buttons name
			if slotNumber and tonumber(slotNumber) then -- ensure it got a number and it can be converted to a number
				manageItemEquipmentEvent:FireServer(tonumber(slotNumber)) -- give the server the slot number to equip/uneqip the slot
			end
		end)
	end
end

-- \\ Connections

userInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end -- make sure the player isnt doing something like typing 
	
	if inputs[input.KeyCode] then -- check the input is valid
		manageItemEquipmentEvent:FireServer(inputs[input.KeyCode]) -- send request for the slot to be equipped
	elseif input.KeyCode == Enum.KeyCode.Q then -- player clicked the key to drop the item
		manageItemEquipmentEvent:FireServer("drop") -- send request to the server for the item to be dropped
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then -- player is trying to use the item
		manageItemEquipmentEvent:FireServer("use") -- send request to the server for the item to be used
	end
end) 

setupClickDetection()
