# Inventory System

This is a modular and stack-based inventory built in roblox studio, with an example use as a tree chopping and resource collection system, built for easy integration into other systems and games.

# Features

- Equipping, unequipping, dropping and picking up system.
- Customisable item stacking.
- Hotbar saving with datastores.
- Modular and easy-to-extend design with item templates and tool modules.
  
# How it works

Items which need to be picked up are added into a folder in the workspace named "DroppedItems". Once a child is added into this folder, code runs to connect a click event to the item so it can be detected to be picked up.
Once clicked, an item is attempted to be added to the players hotbar, ensuring it isn't full and merging it onto an existing stack of items if it is stackable and there is space. During this, it is given a unique ID and other stats to make it easily identifiable.
If the item is dropped, it will unequip the item, remove it from the inventory, and it if is stackable and there is a stack equipped, re-equip the stack. It will also clone a model from the templates in replicated storage and drop it infront of the player, placing it in the "DroppedItems" folder.
The datastores save the item data and load the data into the hotbar and UI when the player rejoins.
When the player equips an item, a copy is made from the templates in replicated storage and added into the players character. When they uneqip it, the tool is destroyed. The players equipped item is tracked in a dictionary.

