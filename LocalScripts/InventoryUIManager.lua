-- \\ Services

local replicatedStorage = game:GetService("ReplicatedStorage")
local players =  game:GetService("Players")

-- \\ Remote Events

local updateUiEvent = replicatedStorage.InventorySystem.RemoteEvents.updateUi
local toggleSlotBorderUiEvent = replicatedStorage.InventorySystem.RemoteEvents.toggleSlotBorderUi
local updateStackNumberEvent = replicatedStorage.InventorySystem.RemoteEvents.updateStackNumber

-- \\ Variables

local player = players.LocalPlayer
local playerUi = player.PlayerGui

local inventoryUi = playerUi:WaitForChild("Inventory")
local hotbar = inventoryUi:WaitForChild("Hotbar")

-- \\ Functions

local function updateUi(slot: TextButton, text: string)
	slot.Text = text -- change the slots text to the text passed
end

local function getSlot(slotNumber)
	if not slotNumber then return nil end
	return hotbar:FindFirstChild("slot" .. slotNumber) -- return the slot with the given number
end

local function manageSlotState(slotNumber, text)
	local slot = getSlot(slotNumber) -- get the slot with the given number
	if not slot then return end

	updateUi(slot, text) -- update the ui
end

local function toggleSlotBorder(slotNumber)
	local slot = getSlot(slotNumber) -- get the slot
	
	if not slot then
		warn("Couldn't find slot! slotNumber is most likely nil or invalid!")
		return
	end
	
	-- toggle the ui stroke
	if slot:FindFirstChildOfClass("UIStroke") then
		slot:FindFirstChildOfClass("UIStroke"):Destroy() 
	else
		local uiStroke = replicatedStorage.InventorySystem.UiAssets.UIStroke:Clone()
		uiStroke.Parent = slot
	end
end

local function updateStackNumber(slotNumber, newStackNumber)
	local slot = getSlot(slotNumber) -- get the slot with the given number
	if not slot then return end
	
	local stackNumber = slot:FindFirstChild("stackLabel") -- get the stack number
	if not stackNumber then return end
	
	if newStackNumber > 1 then
		stackNumber.Visible = true -- if there is more than 1 item in the stack, make it visible
	else
		stackNumber.Visible = false -- else make it invisible
	end
	
	stackNumber.Text = newStackNumber .. "x" -- update the stack number
end

-- \\ Connections

updateUiEvent.OnClientEvent:Connect(manageSlotState)
toggleSlotBorderUiEvent.OnClientEvent:Connect(toggleSlotBorder)
updateStackNumberEvent.OnClientEvent:Connect(updateStackNumber)

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

