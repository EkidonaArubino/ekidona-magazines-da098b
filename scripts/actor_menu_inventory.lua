

-- called from engine!
--[[
 Refers to when an icon is dragged onto another icon in Actor Inventory Menu
 
 passed parameters:
	itm1 is the object being dragged; may be nil
	itm2 is the object the item is being dragged onto; may be nil
	from_slot is the number value of the slot itm1 is being dragged from;  0 or EDDListType.iInvalid is invalid 
	to_slot is the number value of the slot itm2 is occupying;  0 or EDDListType.iInvalid is invalid 
	
from_slot and to_slot values:
		EDDListType.iInvalid			= 0
		EDDListType.iActorSlot			= 1
		EDDListType.iActorBag			= 2
		EDDListType.iActorBelt			= 3

		EDDListType.iActorTrade			= 4
		EDDListType.iPartnerTradeBag	= 5
		EDDListType.iPartnerTrade		= 6
		EDDListType.iDeadBodyBag		= 7
		EDDListType.iQuickSlot			= 8
		EDDListType.iTrashSlot			= 9
		
ex. if (to_slot == EDDListType.iActorSlot) then 
		printf("dragging item to slot!")
	end
	
--]]
function CUIActorMenu_OnItemDropped(itm1,itm2,from_slot,to_slot)
	--printf("itm1=%s itm2=%s from_slot=%s to_slot=%s",itm1 and itm1:name(),itm2 and itm2:name(),from_slot,to_slot)
	
	if (itm1 and itm2) then
		SendScriptCallback("CUIActorMenu_OnItemDropped",itm1,itm2,from_slot,to_slot)
	end
	
	return true
end

-- called from engine!
function CUIActorMenu_OnItemFocusReceive(itm)
	SendScriptCallback("CUIActorMenu_OnItemFocusReceive",itm)
end

-- called from engine!
function CUIActorMenu_OnItemFocusLost(itm)
	SendScriptCallback("CUIActorMenu_OnItemFocusLost",itm)
end

-- called from engine!
-- useful for when doing npc:use(db.actor) when NPC is alive
-- basically what is available in the corpse loot menu while npc is alive
function CInventory_ItemAvailableToTrade(npc,item)
	-- if (xr_corpse_detection.lootable_table[item:section()]) then 
		-- return true
	-- end
	if (db.actor:has_info("ui_pda") and npc:has_info("npcx_is_companion")) then
		local m_data = alife_storage_manager.get_state()
		if (m_data and m_data.companion_borrow_item and m_data.companion_borrow_item[item:id()]) then
			return true
		end
		return false
	else
		return true
	end
	return false
end

-- called from engine