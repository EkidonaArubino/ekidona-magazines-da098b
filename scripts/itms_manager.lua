---------------------------------------
-- itms_manager
-- by Alundaio
-- heavily edited by Lanforse
---------------------------------

local ini = ini_file("plugins\\itms_manager.ltx")

	--Backpack stash mod
	local BackPackStashEnable = ini:r_bool_ex("backpack_stash","enable",false)
	local BackPackStashAllowInBase = BackPackStashEnable and ini:r_bool_ex("backpack_stash","allow_in_base",false)
	local BackPackStashSpot = BackPackStashEnable and ini:r_string_ex("backpack_stash","map_spot") or "treasure" 
	local BackPackStashEnableTip = BackPackStashEnable and ini:r_bool_ex("backpack_stash","enable_news_tip",false)
	local BackPackStashEnableUi = BackPackStashEnable and ini:r_bool_ex("backpack_stash","enable_ui",false)

	-- Sleep bag mod
	local SleepBagEnable = ini:r_bool_ex("sleeping_bag","enable",true)
	local SleepBagRadius = SleepBagEnable and ini:r_float_ex("sleeping_bag","unsafe_radius") or 5000
	local SleepBagPlaceable = SleepBagEnable and ini:r_bool_ex("sleeping_bag","use_placeable",false)
	local SleepBagGameStart = SleepBagEnable and ini:r_bool_ex("sleeping_bag","have_at_start",false)
	local SleepBagSections = SleepBagEnable and alun_utils.collect_section(ini,"sleeping_bag_sections",true)
	local SleepBagPlaceableSections = SleepBagEnable and alun_utils.collect_section(ini,"sleeping_bag_ph_sections",true)

	-- Actor backpack mod
	local ActorBackPackEnable = ini:r_bool_ex("actor_backpack","enable",false)
	local ActorBackPackSpot = ActorBackPackEnable and ini:r_string_ex("actor_backpack","map_spot") or "treasure"
	local ActorBackPackSlot = ActorBackPackEnable and ini:r_string_ex("actor_backpack","quick_slot") or "slot_3"
	local ActorBackPackKeep = ActorBackPackEnable and alun_utils.collect_section(ini,"actor_backpack_keep_items",true)
	local ActorBackPackForced = ActorBackPackEnable and ini:r_bool_ex("actor_backpack","actor_backpack_always_have",false)
	
	local AllowStack = alun_utils.collect_section(ini,"stackable",true)
	local ArtContainer = alun_utils.collect_section(ini,"art_containers",true)
	local RepairTools = alun_utils.collect_section(ini,"repair_mod_tools",true)
	local CookingTools = alun_utils.collect_section(ini,"cooking_mod_tools",true)
	

-- Static Message
ShowMessage = nil
ShowMessageInit = nil
ShowMessageTime = nil

MutantLootDecayTime = 12000
	
Torch2 = false
TorchType = 0

function on_game_start()
	RegisterScriptCallback("on_game_load",on_game_load)
	RegisterScriptCallback("actor_on_update",actor_on_update)
	RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("actor_on_item_drop",actor_on_item_drop)
	RegisterScriptCallback("monster_on_actor_use_callback",monster_on_actor_use_callback)
	RegisterScriptCallback("actor_on_item_use",actor_on_item_use)
	RegisterScriptCallback("actor_on_item_take",actor_on_item_take)
	RegisterScriptCallback("actor_on_item_take_from_box",actor_on_item_take_from_box)
	RegisterScriptCallback("actor_on_item_take_from_ground",actor_on_item_take_from_ground)
	RegisterScriptCallback("npc_on_item_take",npc_on_item_take)
	RegisterScriptCallback("physic_object_on_use_callback",physic_object_on_use_callback)
	RegisterScriptCallback("on_key_press",on_key_press)

	RegisterScriptCallback("CUIActorMenu_OnItemDropped",on_item_drag_dropped)
	RegisterScriptCallback("CUIActorMenu_OnItemFocusReceive",on_item_focus)
end

function on_game_load()


	if (ActorBackPackEnable and ActorBackPackForced) then
		local actor_itm_backpack_id= utils.load_var(db.actor,"actor_itm_backpack_id",nil)
		local actor_inv_backpack_id = utils.load_var(db.actor,"actor_inv_backpack_id",nil)
		if (not actor_itm_backpack_id and not actor_inv_backpack_id) then
			get_console():execute(ActorBackPackSlot.." itm_qr")
			local se_obj = alife():create("itm_qr",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
			if (se_obj) then
				utils.save_var(db.actor,"actor_itm_backpack_id",se_obj.id)
			end
		end
	end

	--[[
	if (SleepBagEnable and SleepBagGameStart) then
		local sleepbag_id = utils.load_var(db.actor,"itm_sleepbag_id",nil)
		if (not sleepbag_id) then
			local se_obj = alife():create("itm_sleepbag",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
			utils.save_var(db.actor,"itm_sleepbag_id",se_obj.id)
		end
	end
	--]]
end

function on_item_focus(itm)
	
	--[[
	if (RepairTools[section]) then 
		local ini = system_ini()
		local repair_type = ini:r_string_ex(section,"repair_type")
		if not (repair_type) then 
			return
		end
		
		local function itr(obj)
			if (repair_type == "weapon" and IsWeapon(obj)) then 
				return true 
			elseif (repair_type == "outfit") and (IsOutfit(obj) or IsHeadgear(obj)) then 
				return true
			elseif (repair_type == "all") then 
				local cls = obj:clsid()
				if (IsWeapon(nil,cls) or IsOutfit(nil,cls) or IsHeadgear(nil,cls)) then 
					return true 
				end
			end
			return false
		end 
		
		ActorMenu.get_actor_menu():highlight_for_each_in_slot(itr)
	end 
	--]]
end 

function on_item_drag_dropped(itm1,itm2,from_slot,to_slot)
	on_ammo_drag_dropped(itm1,itm2,from_slot,to_slot)
	on_consumable_drag_dropped(itm1,itm2,from_slot,to_slot)
end

function on_consumable_drag_dropped(itm1,itm2,from_slot,to_slot)

	if (from_slot ~= EDDListType.iActorBag) or (to_slot ~= EDDListType.iActorBag) then 
		return 
	end 

	if (itm1:id() == itm2:id()) then return end
	
	local sec_1 = itm1:section()
	local sec_2 = itm2:section()
	local sec1 = sec_1
	local sec2 = sec_2
	local nsec1 = sec_1
	local nsec2 = sec_2
	local cnt1 = 1
	local ncnt1 = 1
	local cnt2 = 1
	local ncnt2 = 1

	cnt1 = string.find(sec_1,"_",-2) or 0
	if (string.sub(sec_1,-1) == "p") or (string.sub(sec_1,-1) == "s") or (string.sub(sec_1,-1) == "r") or (string.sub(sec_1,-1) == "a") or (string.sub(sec_1,-1) == "b") or (string.sub(sec_1,-1) == "h") or (string.sub(sec_1,-1) == "e") then
		cnt1 = 0
	end
	sec1 = string.sub(sec_1,0,cnt1-1)
	cnt1 = tonumber(string.sub(sec_1,cnt1+1)) or 1
	ncnt1 = cnt1
	
	cnt2 = string.find(sec_2,"_",-2) or 0
	if (string.sub(sec_2,-1) == "p") or (string.sub(sec_2,-1) == "s") or (string.sub(sec_2,-1) == "r") or (string.sub(sec_2,-1) == "a") or (string.sub(sec_2,-1) == "b") or (string.sub(sec_2,-1) == "h") or (string.sub(sec_2,-1) == "e") then
		cnt2 = 0
	end
	sec2 = string.sub(sec_2,0,cnt2-1)
	cnt2 = tonumber(string.sub(sec_2,cnt2+1)) or 1
	ncnt2 = cnt2
	
	if (sec1 ~= sec2) then return end
	if not AllowStack[sec1] then return end
	
	for i = 1, cnt1 do
	
		ncnt2 = cnt2+i
		ncnt1 = cnt1-i
		
		if (system_ini():section_exist(sec2.."_"..ncnt2) and (ncnt1 >= 0)) then
			nsec2 = sec2.."_"..ncnt2
			nsec1 = sec1.."_"..ncnt1
			
			if (string.find(nsec1,"_1",-2)) then
				nsec1 = sec1
			elseif (string.find(nsec1,"_0",-2) and not system_ini():section_exist(nsec1)) then
				nsec1 = nil
			end
		end
	end
	
	if (nsec1 ~= sec_1) and (nsec2 ~= sec_2) then
		alife():release(alife_object(itm1:id()), true)
		alife():release(alife_object(itm2:id()), true)
		
		alife():create(nsec2, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		if (nsec1) then
			alife():create(nsec1, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		
		xr_sound.set_sound_play(db.actor:id(),"inv_stack")
	end
end

function on_ammo_drag_dropped(itm1,itm2,from_slot,to_slot)

	--printf("itm1=%s itm2=%s from_slot=%s to_slot=%s",itm1 and itm1:name(),itm2 and itm2:name(),from_slot,to_slot)
	---[[
	if (from_slot ~= EDDListType.iActorBag and from_slot ~= EDDListType.iActorBelt) then 
		return 
	end 

	if (itm1:id() == itm2:id()) then return end
	
	if not (to_slot == EDDListType.iActorSlot or to_slot == EDDListType.iActorBag) then 
		return 
	end
	
	local sec1 = itm1:section()
	local sec2 = itm2:section()
	--printf("MOVE "..sec1.." TO "..sec2)
	
	if (IsArtefact(itm1) and ArtContainer[sec2]) then
		container_add(itm1,itm2)
	elseif (IsArtefact(itm2) and ArtContainer[sec1]) then 
		container_add(itm2,itm1)
	end
	
	
	if (IsAmmo(itm1) and IsAmmo(itm2)) and (sec1 == sec2) then
	
		local ammo1 = itm1:ammo_get_count()
		local ammo2 = itm2:ammo_get_count()
		local box1 = itm1:ammo_box_size()
		local box2 = itm2:ammo_box_size()
	
		local fill = utils.clamp(box2-ammo2,0,ammo1)
		
		if (fill > 0) then
			xr_sound.set_sound_play(db.actor:id(),"inv_stack")
			itm2:ammo_set_count(ammo2+fill)
			itm1:ammo_set_count(ammo1-fill)
		end
		
		if (fill == ammo1) then
			alife():release(alife_object(itm1:id()), true)
		end
	end --local fgren=system_ini():r_string_ex(sec1,"fake_grenade_name")
	if(utils.is_ammo(sec1) and IsWeapon(itm2))then --local in_slot=false -- or(fgren and fgren~="")
		for i=1,14 do if(db.actor:item_in_slot(i) and db.actor:item_in_slot(i):id()==itm2:id())then
			in_slot=true break -- Scripted by Ekidona Arubino || 02.12.22 || 20:17(JST)
		end end --[[if not(in_slot)then return end]] local ammotype=ekidona_mags.SelectAmmoType(itm2,sec1)
		if not(ammotype)or(ekidona_mags.isMWeapon(sec2))then return
			--[[if(ekidona_mags.GetWeaponGrenadeLauncher(itm2))then if(sec1~=system_ini():r_string_ex(sec2,"grenade_class"))then return end
				ekidona_mags.SetReloadArray({1,nil,0,nil,itm2:id(),{false,itm1:id()}}) --get_hud():HideActorMenu()
				CreateTimeEvent("EkiMagsReload",itm2:id(),0,ekidona_mags.PlayReloadAnimation,itm2)
			else return end]]
		else local curammo={ekidona_mags.SelectAmmoTypeName(itm2,itm2:get_ammo_type()),itm2:get_ammo_in_magazine(),system_ini():r_float_ex(sec2,"ammo_mag_size")}
			--[[itm2:iterate_installed_upgrades(function(usec) local upset=system_ini():r_string_ex(usec,"section")
				curammo[3]=(system_ini():r_float_ex(upset,"ammo_mag_size") or curammo[3])
			end) meh]]
			if(curammo[1]==sec1 and curammo[2]==curammo[3])then return end local ammoneed=0
			if(curammo[1]~=sec1 and curammo[2]>0)then create_ammo(curammo[1],db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,curammo[2]) curammo[2]=0 end
			if(system_ini():r_string_ex(sec2,"tri_state_reload")=="on")or(system_ini():r_string_ex(sec2,"class")=="WP_BM16")then xr_sound.set_sound_play(db.actor:id(),"reload_shell")
				ekidona_mags.SetWeaponAmmoParams(itm2,ammotype,curammo[2]+1) if(itm1:ammo_get_count()==1)then alife():release(alife_object(itm1:id()))
				else itm1:ammo_set_count(itm1:ammo_get_count()-1)end return
			else ammoneed=math.min(itm1:ammo_get_count(),curammo[3]-curammo[2])end
			--if(itm1:ammo_get_count()-ammoneed<=0)then alife():release(alife_object(itm1:id()))else itm1:ammo_set_count(itm1:ammo_get_count()-ammoneed)end
			ekidona_mags.SetReloadArray({curammo[2]+ammoneed,ammoneed,ammotype,nil,itm2:id(),{false,itm1:id()}}) --get_hud():HideActorMenu()
			CreateTimeEvent("EkiMagsReload",itm2:id(),0,ekidona_mags.PlayReloadAnimation,itm2)
		end
	end
end 

function on_key_press(key)	
	local torch = db.actor:object("device_torch")
	
	
	
	if (dik_to_bind(key) == key_bindings.kTORCH) and (torch) then
	--[[
		local obj = db.actor:active_detector()
		if (torch and obj and FlashlightSections[obj:section()]) then
			FlashlightFar = not FlashlightFar
			xr_sound.set_sound_play(db.actor:id(),"torch_switch1")
		elseif (torch and has_alife_info("enable_device_torch")) then
			xr_sound.set_sound_play(db.actor:id(),"torch_switch2")
			if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == true) then
				local upd = db.actor:object("wpn_upd")
				if not (upd and (upd:condition() > 0.05)) then return end	
			end
		--]]
		
		if (has_alife_info("enable_device_torch")) then
			xr_sound.set_sound_play(db.actor:id(),"torch_switch2")
			
			local upd = db.actor:object("wpn_upd")
			if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == false) or	(upd and (upd:condition() > 0.05)) then
				Torch2 = not Torch2
				torch:enable_torch2(Torch2)
			elseif upd then
				axr_battery.show_message("st_upd_low",25)
			else
				axr_battery.show_message("st_upd_disconnected",25)
			end
		end
		
	elseif (dik_to_bind(key) == key_bindings.kNIGHT_VISION) and (torch) then
		torch:enable_night_vision(not torch:night_vision_enabled())
		
		if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == true) and (torch:night_vision_enabled()) then
			local upd = db.actor:object("wpn_upd")
			if (upd and (upd:condition() < 0.05)) then
				axr_battery.show_message("st_upd_low",25)
				torch:enable_night_vision(false)
				return
			elseif not upd then
				axr_battery.show_message("st_upd_disconnected",25)
				torch:enable_night_vision(false)
				return
			end
		end
	
	elseif (dik_to_bind(key) == 52) then
		---[[
		if (IsLastStandMode() and not DEV_DEBUG_DEV) then return end
		
		local battery = db.actor:object("wpn_upd")
		local batcon = battery and battery:condition()
		if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == false) or (batcon and batcon > 0.05) then
			local pda_menu = ActorMenu.get_pda_menu()
			if not (pda_menu:IsShown()) then 
				pda_menu:ShowDialog(true)
			else
				pda_menu:HideDialog()
			end
		elseif (battery) then
			axr_battery.show_message("st_upd_low",25)
		else
			axr_battery.show_message("st_upd_disconnected",25)
		end
		--]]
	end
end


function actor_on_first_update()
	local torch = db.actor:object("device_torch")
	if (torch) then torch:enable_torch2(false) end
end

local actor_fill_backpack
function actor_on_update()
	
	check_actor_backpack()

	local torch = db.actor:object("device_torch")
	if (torch) then
		
		if (not torch:torch_enabled()) then torch:enable_torch(true) end
		TorchType = 0
		
		local obj = db.actor:active_detector()
		
		if (obj) then
			if (obj:section() == "device_flashlight") then
				if ((obj:get_state() == 0)) then
					TorchType = 1
				end
			elseif (obj:section() == "device_glowstick") then
				TorchType = 3
			elseif (obj:section() == "device_lighter") then
				if ((obj:get_state() == 0)) then
					TorchType = 4
				end
			end
		end
	end
	
	if (db.actor:object("geiger")) then
		local upd = db.actor:object("wpn_upd")
		if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == false) or	(upd and (upd:condition() > 0.05)) then
			db.actor:set_radiation_detector(true)
		else
			db.actor:set_radiation_detector(false)
		end
	else
		db.actor:set_radiation_detector(false)
	end
end
-- bind_stalker on_trade
function actor_on_trade(obj,sell_bye,money)

end

-- bind_stalker on_item_drop
function actor_on_item_drop(obj)
	if not (obj) then
		return
	end
	if (ActorBackPackEnable and ActorBackPackForced and obj:section() == "itm_qr") then
		local se_itm = alife():create("itm_qr",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())

		if not (se_itm) then
			return
		end

		utils.save_var(db.actor,"actor_itm_backpack_id",se_itm.id)
		alife():release( alife_object(obj:id()) )
	end
	
	if (db.actor:has_info("actor_made_wish_for_riches")) then 
		db.actor:transfer_item(obj,db.actor)
	end

end

function monster_on_actor_use_callback(obj,who)	
	local ini = system_ini()
	local class = ini:r_string_ex(obj:section(),"class")
	
	if (class == "SM_RAT") then
		alife():release( alife_object(obj:id()) )
		alife():create("mutant_part_rat_corpse",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())
		return
	end

	local st = db.storage[obj:id()]
	if (st and st.death_time and game.get_game_time():diffSec(st.death_time) > MutantLootDecayTime) then
		SetHudMsg(game.translate_string("st_body_decayed"),4)
	else
		local hud = get_hud()
		if (hud) then
			ui_mutant_loot.loot_ui(hud,obj)
		end
	end
end


-- bind_stalker on_item_use
function actor_on_item_use(obj)
	if (db.actor:has_info("actor_made_wish_for_riches")) then
		return 
	end
	
	-- Backpack
	if (BackPackStashEnable and obj:section() == "itm_backpack") then

		if (BackPackStashAllowInBase ~= true) then
			local in_base
			local zone
			local t = {"zat_a2_sr_no_assault","jup_a6_sr_no_assault","jup_b41_sr_no_assault"}
			for i=1,#t do
				zone = db.zone_by_name[t[i]]
				if (zone and zone:inside(db.actor:position())) then
					in_base = true
					break
				end
			end

			if (in_base) then
				SetHudMsg(game.translate_string("st_stash_unsafe"),4)
				alife():create("itm_backpack",db.actor:position(),0,0,0)
				return
			end
		end

		local se_obj = alife():create("inv_backpack",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id())
		if (se_obj) then
			local level_name = level.name()
			coc_treasure_manager.caches[se_obj.id] = false

			if not (BackPackStashEnableUi) then
				local count = utils.load_var(db.actor, level_name.."bpk_count", 0)
				utils.save_var(db.actor, level_name.."bpk_count", count+1)
				level.map_add_object_spot_ser(se_obj.id, BackPackStashSpot, game.translate_string(level_name).." "..game.translate_string("st_itm_stash").." "..count+1)
			else
				local hud = get_hud()
				if (hud) then
					hud:HideActorMenu()
					local ui = ui_itm_backpack and ui_itm_backpack.backpack_ui(hud,se_obj.id,BackPackStashSpot)
					if (ui) then
						ui:ShowDialog(true)
					end
				end
			end

			if (BackPackStashEnableTip) then
				SetHudMsg(game.translate_string("st_stash_created"),4)
			end
		end
		return
	end

	-- Sleeping bag
	if (SleepBagEnable and SleepBagSections[obj:section()]) then
		local sec = obj:section()
		if (SleepBagPlaceable) then
			local ph_sec = system_ini():r_string_ex(sec,"placeable_section")
			local se_obj = alife():create(ph_sec or "ph_sleepbag",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id())if (se_obj) then
			local rot = device().cam_dir:getH()
				se_obj.angle = vector():set(0,rot,0)
			end
			local compr = alife():create("compression_bag",db.actor:position(),0,0,0)
				
			level.map_add_object_spot_ser(se_obj.id, "ui_pda2_actor_sleep_location", game.translate_string("st_itm_sleepbag_name"))
		else
			local se_obj = alife():create(sec,db.actor:position(),0,0,0)
			local hud = get_hud()
			if (hud) then
				hud:HideActorMenu()
			end
			local ui = ui_sleep_dialog.sleep_bag(se_obj,sec)
		end
		return
	end
	
	-- Compression bag
	if (obj:section() == "compression_bag") then
		for i=1,65534 do
			local s = alife_object(i)
			if s then
				local o = level.object_by_id(s.id)
				if o  then
					local slbag = o:section()
					if slbag == "ph_sleepbag" and o:position():distance_to(db.actor:position()) < 1 then
						level.map_remove_object_spot(s.id, "ui_pda2_actor_sleep_location")
						alife():create("itm_sleepbag",db.actor:position(),0,0,0)
						alife():release(s)
						alife():release(alife_object(obj:id()))
						actor_effects.use_item("itm_sleepbag")
						break
					end
				end
			end
		end
	end
	
	if (obj:section() =="tent") then
		local pos = db.actor:position()
		--pos:add(device().cam_dir:mul(1.2))
		--pos.y = db.actor:position().y
		
		local lvid = db.actor:level_vertex_id()
		local gvid = db.actor:game_vertex_id()
		local se_obj = alife():create("ph_tent",pos,lvid,gvid)
		if (se_obj) then
			local rot = device().cam_dir:getH()
			se_obj.angle = vector():set(0,rot,0)
		end
	end

	-- Actor backpack
	if (ActorBackPackEnable and obj:section() == "itm_qr") then
		local id = ActorBackPackForced and utils.load_var(db.actor,"actor_inv_backpack_id",nil)
		if (id) then
			SetHudMsg(game.translate_string("st_stash_placed"),4)
			alife():create("itm_qr",db.actor:position(),0,0,0)
			return
		end

		local se_obj = alife():create("inv_actor_backpack",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id())
		
		coc_treasure_manager.caches[se_obj.id] = false

		level.map_add_object_spot_ser(se_obj.id, ActorBackPackSpot, strformat(game.translate_string("st_itm_stash_of_character"),db.actor:character_name()))

		utils.save_var(db.actor,"actor_inv_backpack_id",se_obj.id)
	end

	-- Repair mod
	if (RepairTools[obj:section()]) then
		local hud = get_hud()
		if (hud) then
			hud:HideActorMenu()
			local ui = ui_itm_repair and ui_itm_repair.repair_ui(hud,obj,obj:section())
			if (ui) then
				ui:ShowDialog(true)
				ui:FillList()
			end
		end
	end
	
	-- Craft mod
	if 	(obj:section() == "itm_repairkit_tier_1") or
		(obj:section() == "itm_repairkit_tier_2") or
		(obj:section() == "itm_repairkit_tier_3") or
		(obj:section() == "itm_drugkit") then
		local hud = get_hud()
		hud:HideActorMenu()
		local ui = ui_itm_craft and ui_itm_craft.craft_ui(hud,obj:section())
		if (ui) then
			ui:ShowDialog(true)
			ui:FillCraftList()
		end	
	end
	
	-- Cooking mod
	if (CookingTools[obj:section()]) then
		local hud = get_hud()
		hud:HideActorMenu()
		local ui = ui_itm_cooking and ui_itm_cooking.cooking_ui(hud,obj:section())
		if (ui) then
			ui:ShowDialog(true)
			ui:FillList()
		end
	end
	
	if (obj:section() =="wood_stove") then
		local pos = db.actor:position()
		pos:add(device().cam_dir:mul(1.2))
		pos.y = db.actor:position().y
		
		local lvid = db.actor:level_vertex_id()
		local gvid = db.actor:game_vertex_id()
		local se_obj = alife():create("ph_woodstove",pos,lvid,gvid)
		if (se_obj) then
			local rot = device().cam_dir:getH()+3.14
			se_obj.angle = vector():set(0,rot,0)
		end
	end
	
	if (obj:section() =="fieldcooker") then
		local pos = db.actor:position()
		pos:add(device().cam_dir:mul(1.2))
		pos.y = db.actor:position().y
		
		local lvid = db.actor:level_vertex_id()
		local gvid = db.actor:game_vertex_id()
		local se_obj = alife():create("ph_fieldcooker",pos,lvid,gvid)
		if (se_obj) then
			local rot = device().cam_dir:getH()+3.14
			se_obj.angle = vector():set(0,rot,0)
		end
	end

	-- Dummy Torch for Flashlight
	if (obj:section() == "device_torch_dummy") then
		local torch = db.actor:object("device_torch")
		if not (has_alife_info("enable_device_torch")) then
			give_info("enable_device_torch")
			SetHudMsg(game.translate_string("st_lamp_equipped"),4)
		end
	end
	
	-- Deployable mgun
	if (obj:section() == "itm_deployable_mgun") then
		local pos = vector():set(device().cam_pos)
		pos:add(device().cam_dir:mul(3))
		alife():create("deployable_mgun",pos,level.vertex_id(pos),db.actor:game_vertex_id())
	end
	
	-- Geiger
	if (obj:section() == "geiger") then
		local upd = db.actor:object("wpn_upd")
		if (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == false) or	(upd and (upd:condition() > 0.05)) then
			local text = game.translate_string("st_rad_level")..": "..math.floor(db.actor.radiation*10000*1).." "..game.translate_string("st_msv")
			SetHudMsg(text,3)
			if (upd) and (axr_main.config:r_value("mm_options","enable_use_battery",1,false) == true) then
				upd:set_condition(upd:condition() - 0.005)
			end
		elseif (upd) then
			axr_battery.show_message("st_upd_low",25)
		else
			axr_battery.show_message("st_upd_disconnected",25)
		end
	end
	
	-- MAPS
	if (obj:section() == "maps_kit") then
		if (not IsLastStandMode()) then
			pda.open_random_anomaly()
			pda.open_random_anomaly()
			pda.open_random_anomaly()
		else
			alife():create("maps_kit", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
	end
	
	if (obj:section() == "mili_maps") then
		if (not IsLastStandMode()) then
			pda.open_random_anomaly()
			pda.open_random_anomaly()
			pda.open_random_anomaly()
			pda.open_random_anomaly()
			pda.open_random_anomaly()
		else
			alife():create("mili_maps", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
	end
	
	if (obj:section() == "journal") then
		if (not IsLastStandMode()) then
			coc_treasure_manager.create_random_stash(nil,nil,nil)
		else
			alife():create("journal", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
	end
	
	
	-- PSY
	local eat_psy = alun_utils.read_from_ini(nil,obj:section(),"eat_psy","float",0)
	db.actor.psy_health = eat_psy
	
	-- PERKS
	if (db.actor:has_info("perk_strong_stomach")) then
		local eat_health = alun_utils.read_from_ini(nil,obj:section(),"eat_health","float",0)
		local eat_radiation = alun_utils.read_from_ini(nil,obj:section(),"eat_radiation","float",0)
		if (eat_health < 0) then db.actor:set_health_ex(db.actor.health-eat_health*0.5) end
		if (eat_radiation > 0) then db.actor.radiation = -eat_radiation*0.3 end
	end
	
	if (db.actor:has_info("perk_gourmet")) then
		local eat_satiety = alun_utils.read_from_ini(nil,obj:section(),"eat_satiety","float",0)
		if (eat_satiety > 0) then db.actor.satiety = eat_satiety*0.3 end
	end
	
	------------------- FFFFFFFFUUUUUUUUUUUUUUUUUUUUUUU ---------------------------
	local s_obj = alife_object(obj:id())
	
    -- ponney68 Multi usage items
	-- Combat Rations		
	-- ration_ukr x6
	if(s_obj)and(s_obj:section_name()=="ration_ukr_6")then
    	alife():create("ration_ukr_5", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ukr_5")then
    	alife():create("ration_ukr_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ukr_4")then
    	alife():create("ration_ukr_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ukr_3")then
    	alife():create("ration_ukr_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ukr_2")then
    	alife():create("ration_ukr", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- ration_ru x7
	if(s_obj)and(s_obj:section_name()=="ration_ru_7")then
    	alife():create("ration_ru_6", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ru_6")then
    	alife():create("ration_ru_5", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ru_5")then
    	alife():create("ration_ru_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ru_4")then
    	alife():create("ration_ru_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ru_3")then
    	alife():create("ration_ru_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="ration_ru_2")then
    	alife():create("ration_ru", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- mre x3
	if(s_obj)and(s_obj:section_name()=="mre_3")then
    	alife():create("mre_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="mre_2")then
    	alife():create("mre", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

	-- IMPORTED DRINK
	-- vodka x3
	if(s_obj)and(s_obj:section_name()=="vodka_3")then
    	alife():create("vodka_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="vodka_2")then
    	alife():create("vodka", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- vodka_quality x3
	if(s_obj)and(s_obj:section_name()=="vodka_quality_3")then
    	alife():create("vodka_quality_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="vodka_quality_2")then
    	alife():create("vodka_quality", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- mineral_water x3
	if(s_obj)and(s_obj:section_name()=="mineral_water_3")then
    	alife():create("mineral_water_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="mineral_water_2")then
    	alife():create("mineral_water", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

	-- ZONE-PRODUCED DRINK
	-- bottle_metal x3
	if(s_obj)and(s_obj:section_name()=="bottle_metal_3")then
    	alife():create("bottle_metal_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="bottle_metal_2")then
    	alife():create("bottle_metal", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- tea x3
	if(s_obj)and(s_obj:section_name()=="tea_3")then
    	alife():create("tea_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="tea_2")then
    	alife():create("tea", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- flask x3
	if(s_obj)and(s_obj:section_name()=="flask_3")then
    	alife():create("flask_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="flask_2")then
    	alife():create("flask", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

	-- ZONE-PRODUCED SMOKES
	-- marijuana x3
	if(s_obj)and(s_obj:section_name()=="marijuana_3")then
    	alife():create("marijuana_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="marijuana_2")then
    	alife():create("marijuana", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

	-- IMPORTED SMOKES
	-- cigarettes x3
	if(s_obj)and(s_obj:section_name()=="cigarettes_3")then
    	alife():create("cigarettes_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigarettes_2")then
    	alife():create("cigarettes", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- cigar1 x3
	if(s_obj)and(s_obj:section_name()=="cigar1_3")then
    	alife():create("cigar1_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigar1_2")then
    	alife():create("cigar1", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- cigar2 x3
	if(s_obj)and(s_obj:section_name()=="cigar2_3")then
    	alife():create("cigar2_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigar2_2")then
    	alife():create("cigar2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- cigar3 x3
	if(s_obj)and(s_obj:section_name()=="cigar3_3")then
    	alife():create("cigar3_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigar3_2")then
    	alife():create("cigar3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- tobacco x3
	if(s_obj)and(s_obj:section_name()=="tobacco_3")then
    	alife():create("tobacco_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="tobacco_2")then
    	alife():create("tobacco", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- hand_rolling_tobacco x3
	if(s_obj)and(s_obj:section_name()=="hand_rolling_tobacco_3")then
    	alife():create("hand_rolling_tobacco_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="hand_rolling_tobacco_2")then
    	alife():create("hand_rolling_tobacco", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- cigarettes_lucky x3
	if(s_obj)and(s_obj:section_name()=="cigarettes_lucky_3")then
    	alife():create("cigarettes_lucky_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigarettes_lucky_2")then
    	alife():create("cigarettes_lucky", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- cigarettes_russian x3
	if(s_obj)and(s_obj:section_name()=="cigarettes_russian_3")then
    	alife():create("cigarettes_russian_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cigarettes_russian_2")then
    	alife():create("cigarettes_russian", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

	-- MEDICAL ITEMS
	-- caffeine x5
	if(s_obj)and(s_obj:section_name()=="caffeine_5")then
    	alife():create("caffeine_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="caffeine_4")then
    	alife():create("caffeine_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="caffeine_3")then
    	alife():create("caffeine_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="caffeine_2")then
    	alife():create("caffeine", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	-- cocaine x3
	if(s_obj)and(s_obj:section_name()=="cocaine_3")then
    	alife():create("cocaine", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="cocaine_2")then
    	alife():create("cocaine", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		
		-- DRUGS
		-- drug_charcoal x5
	if(s_obj)and(s_obj:section_name()=="drug_charcoal_5")then
    	alife():create("drug_charcoal_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_charcoal_4")then
    	alife():create("drug_charcoal_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_charcoal_3")then
    	alife():create("drug_charcoal_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_charcoal_2")then
    	alife():create("drug_charcoal", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- drug_coagulant x5
	if(s_obj)and(s_obj:section_name()=="drug_coagulant_5")then
    	alife():create("drug_coagulant_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_coagulant_4")then
    	alife():create("drug_coagulant_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_coagulant_3")then
    	alife():create("drug_coagulant_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_coagulant_2")then
    	alife():create("drug_coagulant", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- drug_psy_blockade x5
	if(s_obj)and(s_obj:section_name()=="drug_psy_blockade_5")then
    	alife():create("drug_psy_blockade_4", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_psy_blockade_4")then
    	alife():create("drug_psy_blockade_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_psy_blockade_3")then
    	alife():create("drug_psy_blockade_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="drug_psy_blockade_2")then
    	alife():create("drug_psy_blockade", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- drug_antidot x2
	if(s_obj)and(s_obj:section_name()=="drug_antidot_2")then
    	alife():create("drug_antidot", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- drug_radioprotector x2
	if(s_obj)and(s_obj:section_name()=="drug_radioprotector_2")then
    	alife():create("drug_radioprotector", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- akvatab x4
	if(s_obj)and(s_obj:section_name()=="akvatab_3")then
    	alife():create("akvatab_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="akvatab_2")then
    	alife():create("akvatab", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end

		-- IMPORTED FOOD
		-- mint x5
	if(s_obj)and(s_obj:section_name()=="mint_3")then
    	alife():create("mint_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
	if(s_obj)and(s_obj:section_name()=="mint_2")then
    	alife():create("mint", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
    end
		-- End ponney68 
end

function check_actor_backpack()
	if (db.actor:has_info("actor_filled_backpack"))then
		return
	end

	local id = utils.load_var(db.actor,"actor_inv_backpack_id",nil)

	if not (id) then
		return
	end

	local se_obj = alife_object(id)
	if not (se_obj) then 
		return 
	end
	local st = db.storage[se_obj.id]
	local obj = st and st.object or level.object_by_id(id)

	if not (obj) then
		return
	end

	if (db.actor:has_info("actor_made_wish_for_riches")) then
		return 
	end
	
	local function itr_inv(temp,item)
		local id = item and item:section() ~= "itm_qr" and ActorBackPackKeep[item:section()] == nil and item:id()
		if (id) then
			local itm_slot
			local equipped
			for i=1,14 do
				itm_slot = db.actor:item_in_slot(i)
				if (itm_slot and itm_slot:id() == id) then
					equipped = true
					break
				end
			end
			
			if (db.actor:is_on_belt(item)) then
				equipped = true
			end

			if (not equipped) then
				db.actor:transfer_item(item,obj)
			end
			equipped = nil
		end
	end

	db.actor:iterate_inventory(itr_inv)

	db.actor:give_info_portion("actor_filled_backpack")
end

function actor_on_item_take_from_ground(obj)

	if not (obj) then
		return
	end
	
	xr_sound.set_sound_play(db.actor:id(),"inv_take")
	
	if (axr_main.config:r_value("mm_options","enable_ground_items",1,false) == true) then
		db.actor:give_game_news("", game.translate_string(system_ini():r_string_ex(obj:section(),"inv_name")), "ui_iconsTotal_grouping", 0, 200)
	end
end

function actor_on_item_take(obj)

	if not (obj) then
		return
	end
	
	if (DEV_DEBUG_DEV) then
		printf("itms_manager.actor_on_item_take: "..obj:section())
	end

	if (obj:section() == "explosive_mobiltank")
	or (obj:section() == "explosive_tank")
	then
		alife():release(alife_object(obj:id()) ,true)
		local fuel = math.random(2,4)
		alife():create("explo_jerrycan_fuel_"..fuel,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())
	end
end

-- bind_stalker take_item_from_iventory_box
function actor_on_item_take_from_box(box,obj)
	if not (box) then
		return
	end

	if not (obj) then
		return
	end

	-- Backpack section
	if (BackPackStashEnable and box:section() == "inv_backpack") then
		if (box:is_inv_box_empty()) then
			local hud = get_hud()
			if (hud) then
				hud:HideActorMenu()
			end

			level.map_remove_object_spot(box:id(), BackPackStashSpot)
			alife():create("itm_backpack",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())

			alife():release( alife_object(box:id()) ,true)
			coc_treasure_manager.caches[box:id()] = nil
		end
	end

	-- Actor backpack section
	if (ActorBackPackEnable and box:section() == "inv_actor_backpack") then
		if (box:is_inv_box_empty()) then
			local hud = get_hud()
			if (hud) then
				hud:HideActorMenu()
			end

			level.map_remove_object_spot(box:id(), BackPackActorSpot)

			alife():release( alife_object(box:id()) ,true)

			alife():create("itm_qr",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())

			coc_treasure_manager.caches[box:id()] = nil
			utils.save_var(db.actor,"actor_inv_backpack_id",nil)
			db.actor:disable_info_portion("actor_filled_backpack")
		end
	end
end


function npc_on_item_take(npc,item)


	if not (npc:alive()) then return end

	local id = npc:id()
	local st = db.storage[id]
	if not (st) then return	end

	if not (db.actor) then return end
	
	utils.save_var(npc,item:id(),true)
end

-- bind_physic_object use_callback
function physic_object_on_use_callback(obj,who)
	if (SleepBagEnable and SleepBagPlaceableSections[obj:section()]) then
		local hud = get_hud()
		if (hud) then
			hud:HideActorMenu()
		end
		ui_sleep_dialog.sleep_bag(obj:id(),SleepBagPlaceableSections[obj:section()])
	end
	
	
	if (obj:section() == "ph_woodstove") then
		local hud = get_hud()
		hud:HideActorMenu()
		local ui = ui_itm_cooking and ui_itm_cooking.cooking_ui(hud,"wood_stove",obj)
		if (ui) then
			ui:ShowDialog(true)
			ui:FillList()
		end
	end
	
	if (obj:section() == "ph_fieldcooker") then
		local hud = get_hud()
		hud:HideActorMenu()
		local ui = ui_itm_cooking and ui_itm_cooking.cooking_ui(hud,"fieldcooker",obj)
		if (ui) then
			ui:ShowDialog(true)
			ui:FillList()
		end
	end
	
	if (obj:section() == "ph_tent") then
		local se_obj = alife():object(obj:id())
		alife():release(se_obj, true)
	end
	
end

function is_ammo_for_wpn(sec)
	local sim = alife()
	for i=2,3 do
		local wpn = db.actor:item_in_slot(i)
		if (wpn) then
			local ammos = alun_utils.parse_list(system_ini(),wpn:section(),"ammo_class",true)
			if (ammos[sec]) then 
				return true 
			end
		end
	end
	return false
end

function loot_mutant(obj,cls,t,npc)
	if not (db.actor) then 
		return 
	end 
	
	local cls = cls or obj and obj:clsid()
	if not (cls) then
		return
	end

	local clsid_to_section = {
		[clsid.bloodsucker_s] 	= "bloodsucker",
		[clsid.boar_s] 			= "boar",
		[clsid.burer_s] 		= "burer",
		[clsid.chimera_s]		= "chimera",
		[clsid.controller_s]	= "controller",
		[clsid.dog_s]			= "dog",
		[clsid.flesh_s]			= "flesh",
		[clsid.gigant_s]		= "gigant",
		[clsid.poltergeist_s]	= "poltergeist",
		[clsid.psy_dog_s]		= "psy_dog",
		[clsid.psy_dog_phantom_s] = "psy_dog",
		[clsid.pseudodog_s]		= "pseudodog",
		[clsid.snork_s]			= "snork",
		[clsid.tushkano_s]		= "tushkano",
		[clsid.cat_s]			= "cat",
		[clsid.fracture_s]		= "fracture",
		[clsid.zombie_s]		= "zombie",
		[clsid.crow]			= "crow",
		[clsid.rat_s]			= "rat"
	}
	
	local loot_table = alun_utils.collect_section(ini,clsid_to_section[cls])

	local loot,sec
	math.randomseed(obj:id())
	for i=1,#loot_table do
		loot = alun_utils.str_explode(loot_table[i],",")
		if (loot and loot[1] and loot[2]) then
			if not (loot[3]) then
				loot[3] = 1
			end
			
			local koef = 1
			
			if (db.actor:item_in_slot(15) ~= nil and db.actor:item_in_slot(15):section() == "kit_hunt") then
				koef = koef+0.5
			end
			
			loot[2] = tonumber(loot[2])
			for i=1,loot[2] do
				if (math.random() <= tonumber(loot[3]*koef)) then
					if (t) then
						local item_section = loot[1]
						if not (t[item_section]) then
							t[item_section] = {}
						end
						t[item_section].count = t[item_section].count and t[item_section].count + 1 or 1
						--printf("loot_mutant")
					end
					if npc and npc:id() ~= db.actor:id() then
						alife():create(loot[1],npc:position(),0,0,npc:id())
					end
				end
			end
		end
	end
	math.randomseed(device():time_global())		
end

function container_remove_menu(itm)
	
	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end

	local sec = itm:section()
	if (string.find(sec, "(lead.-_box)",3))
	or (string.find(sec, "(af.-_iam)",3))
	or (string.find(sec, "(af.-_aac)",3))
	or (string.find(sec, "(af.-_aam)",3))
	then return game.translate_string("st_ui_container_remove") end
	
end

function container_fill_menu(itm)
	
	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end
		
	local sec = itm:section()
	if ((sec == "lead_box") or (sec == "af_iam") or (sec == "af_aam") or (sec == "af_aac"))
	then return game.translate_string("st_ui_container_place") end
end

function container_fill(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end

	local hud = get_hud()
	local ui = ui_itm_container and ui_itm_container.arty_ui(hud,itm)
	if (ui) then
		hud:HideActorMenu()
		ui:ShowDialog(true)
		ui:FillPartsList()
	end
end

function container_remove(con)

	local p = con:parent()
	if not (p and p:id() == db.actor:id()) then return end

	local se_obj = alife_object(con:id())
	if (se_obj) then
		local break_con
		local break_arty
		local sec = con:section()
		local antirad = system_ini():r_string_ex(con:section(),"antirad") or 0
		local weight = system_ini():r_string_ex(con:section(),"inv_weight") or 0
		if (antirad == 0) then weight = 0 end

		printf(antirad.." "..weight)
		
		if (string.find(sec, "(lead.-_box)",3)) then
			break_con = "lead_box"
			break_arty = sec:gsub("_lead_box", "")		
		elseif (string.find(sec, "(af.-_iam)",3)) then
			break_con = "af_iam"
			break_arty = sec:gsub("_af_iam", "")
		elseif (string.find(sec, "(af.-_aac)",3)) then
			break_con = "af_aac"
			break_arty = sec:gsub("_af_aac", "")
		elseif (string.find(sec, "(af.-_aam)",3)) then
			break_con = "af_aam"
			break_arty = sec:gsub("_af_aam", "")
		end
		
		if (break_con and break_arty) then
			local new_se_obj = alife():create(break_arty, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
			new_se_obj.generate 				 = false
			new_se_obj.condition				 = con:condition()
			new_se_obj.offline_condition 		 = con:condition()
			new_se_obj.weight					 = se_obj.weight-weight
			new_se_obj.health_restore_speed		 = se_obj.health_restore_speed
			new_se_obj.radiation_restore_speed	 = se_obj.radiation_restore_speed
			new_se_obj.satiety_restore_speed	 = se_obj.satiety_restore_speed
			new_se_obj.power_restore_speed		 = se_obj.power_restore_speed
			new_se_obj.bleeding_restore_speed	 = se_obj.bleeding_restore_speed
			new_se_obj.additional_inventory_weight = se_obj.additional_inventory_weight
			new_se_obj.burn_immunity			 = se_obj.burn_immunity
			new_se_obj.strike_immunity			 = se_obj.strike_immunity
			new_se_obj.shock_immunity			 = se_obj.shock_immunity
			new_se_obj.wound_immunity			 = se_obj.wound_immunity
			new_se_obj.radiation_immunity		 = se_obj.radiation_immunity
			new_se_obj.telepatic_immunity		 = se_obj.telepatic_immunity
			new_se_obj.chemical_burn_immunity	 = se_obj.chemical_burn_immunity
			new_se_obj.explosion_immunity		 = se_obj.explosion_immunity
			new_se_obj.fire_wound_immunity		 = se_obj.fire_wound_immunity
			
			alife():create(break_con, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
			alife():release(se_obj)
			actor_effects.use_item("container_tool")
		end
	end
end

function container_add(art,con)
	local se_art = alife_object(art:id())
	local se_con = alife_object(con:id())
	
	local weight = system_ini():r_string_ex(con:section(),"inv_weight")
	local antirad = system_ini():r_string_ex(con:section(),"antirad") or 0
	
	if (se_art and se_con) then
		local new_con = art:section().."_"..con:section()
		if system_ini():section_exist(new_con) then
			local new_se_obj = alife():create(new_con, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
			new_se_obj.generate 				 = false
			new_se_obj.condition				 = se_art.offline_condition
			new_se_obj.offline_condition		 = se_art.offline_condition
			new_se_obj.weight					 = art:get_artefact_weight()+weight
			new_se_obj.health_restore_speed		 = art:get_artefact_health()
			new_se_obj.radiation_restore_speed	 = art:get_artefact_radiation()
			new_se_obj.satiety_restore_speed	 = art:get_artefact_satiety()
			new_se_obj.power_restore_speed		 = art:get_artefact_power()
			new_se_obj.bleeding_restore_speed	 = art:get_artefact_bleeding()
			new_se_obj.additional_inventory_weight = art:get_artefact_additional_weight()
			new_se_obj.burn_immunity			 = art:get_artefact_burn_immunity()
			new_se_obj.strike_immunity			 = art:get_artefact_strike_immunity()
			new_se_obj.shock_immunity			 = art:get_artefact_shock_immunity()
			new_se_obj.wound_immunity			 = art:get_artefact_wound_immunity()
			new_se_obj.radiation_immunity		 = art:get_artefact_radiation_immunity()
			new_se_obj.telepatic_immunity		 = art:get_artefact_telepatic_immunity()
			new_se_obj.chemical_burn_immunity	 = art:get_artefact_chemical_burn_immunity()
			new_se_obj.explosion_immunity		 = art:get_artefact_explosion_immunity()
			new_se_obj.fire_wound_immunity		 = art:get_artefact_fire_wound_immunity()

			alife():release(se_art)
			alife():release(se_con)
			actor_effects.use_item(con:section())
		end
	end
end

function randomize_artefacts()
	local sysini = system_ini()
	
	local function randomize(actor,arte)
		if IsArtefact(arte) then
		
			local val = 0
			
			local hit_absorbation_sect = sysini:r_string_ex(arte:section(),"hit_absorbation_sect")
			val = sysini:r_float_ex(arte:section(),"inv_weight") or 0
				--val = val*(math.random(5,15)/10)
				arte:set_artefact_weight(val)
			val = sysini:r_float_ex(arte:section(),"health_restore_speed") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_health(val)
			val = sysini:r_float_ex(arte:section(),"radiation_restore_speed") or 0
				--val = val*(math.random(5,15)/10)
				arte:set_artefact_radiation(val)
			val = sysini:r_float_ex(arte:section(),"satiety_restore_speed") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_satiety(val)
			val = sysini:r_float_ex(arte:section(),"power_restore_speed") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_power(val)
			val = sysini:r_float_ex(arte:section(),"bleeding_restore_speed") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_bleeding(val)
			val = sysini:r_float_ex(arte:section(),"additional_inventory_weight") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_additional_weight(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"burn_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_burn_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"strike_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_strike_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"shock_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_shock_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"wound_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_wound_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"radiation_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_radiation_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"telepatic_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_telepatic_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"chemical_burn_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_chemical_burn_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"explosion_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_explosion_immunity(val)
			val = sysini:r_float_ex(hit_absorbation_sect,"fire_wound_immunity") or 0
				--val = val*(math.random(2,18)/10)
				arte:set_artefact_fire_wound_immunity(val)
		end
	end
	db.actor:iterate_inventory(randomize,db.actor)
end

function is_weapon(section)
	local v = system_ini():r_string_ex(section,"class","")
	return string.find(v,"WP_") ~= nil
end
	
function is_outfit(section)
	local v = system_ini():r_string_ex(section,"class","")
	return v == "EQU_STLK" or v == "E_STLK" or v == "EQU_HLMET" or v == "E_HLMET"
end

function is_consumable(section)
	local v = ini:r_string_ex(section,"class","")
	return v == "S_FOOD" or v == "II_FOOD"
end
	
function inv_item_place_menu(itm)
	return game.translate_string("st_item_place")
end

function inv_item_place(itm)
	
	local section = itm:section()
	local se_itm = alife_object(itm:id())
	alife():release(se_itm)
		
	local pos = db.actor:position()
	pos:add(device().cam_dir:mul(1.2))
	pos.y = db.actor:position().y + 1
	local lvid = db.actor:level_vertex_id()
	local gvid = db.actor:game_vertex_id()
	local obj = alife():create(section,pos,lvid,gvid)
	
	local rot = device().cam_dir:getH()
	obj.angle = vector():set(0,rot,0)
end

function inv_item_sort_ammo_menu(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end
	
	return game.translate_string("st_item_sort")
end

function inv_item_sort_ammo(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end
	
	local section = itm:section()
	local se_itm = alife_object(itm:id())
	alife():release(se_itm)
	
	local max_ammo = math.random(1,5)
	
	
	local ammo_list = {
		"ammo_9x18_fmj",
		"ammo_9x19_fmj",
		"ammo_11.43x23_fmj",
		"ammo_357_hp_mag",
		"ammo_5.45x39_fmj",
		"ammo_5.56x45_ss190",
		"ammo_9x39_pab9",
		"ammo_7.62x39_fmj",
		"ammo_7.62x51_fmj",
		"ammo_7.62x25_p",
		"ammo_7.92x33_fmj",
		"ammo_7.62x54_7h1",
		"ammo_7.62x54_ap",
	}
	
	for i = 1, max_ammo do
		local ammo = ammo_list[math.random(#ammo_list)]
		if (ammo) then		
			create_ammo(ammo,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)
		end
	end
	
end

function inv_item_pour_menu(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end
	
	return game.translate_string("st_item_pour")
end

function inv_item_pour(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end
	
	local section = itm:section()
	local se_itm = alife_object(itm:id())
	alife():release(se_itm)
	
	local new_item
	
	if (string.find(section,"explo_jerrycan_fuel")) then
		new_item = "explo_jerrycan_fuel_0"
		xr_sound.set_sound_play(db.actor:id(),"item_pour")
		actor_effects.use_item("pistol_reload")
	elseif (string.find(section,"explo_balon_gas")) then
		new_item = "explo_balon_gas_0"
		actor_effects.use_item("pistol_reload")
	end
	
	if (new_item) then
		alife():create(new_item, db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
	end
end

function inv_item_dismantle_menu(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end

	return game.translate_string("st_item_dismantle")
end

function inv_item_dismantle(itm)

	local p = itm:parent()
	if not (p and p:id() == db.actor:id()) then return end

	local section = itm:section()
	local condition = itm:condition()
	local se_itm = alife_object(itm:id())
	alife():release(se_itm)
	
	local pos = db.actor:position()
	local lvid = db.actor:level_vertex_id()
	local gvid = db.actor:game_vertex_id()
	local actor = db.actor:id()
	
--
--	if (section == "novice_outfit")
--	or (section == "bandit_novice_outfit") then
--		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
--		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
--		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
--		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
--	elseif (section == "trenchcoat_outfit") then
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		
--	elseif (section == "cs_light_outfit") or
--	(section == "svoboda_light_outfit") or
--	(section == "banditmerc_outfit") or
--	(section == "merc_outfit") then
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_e", pos, lvid, gvid, actor)
--		
--	elseif (section == "stalker_outfit") or
--	(section == "dolg_outfit") or
--	(section == "svoboda_outfit") or
--	(section == "cs_outfit") or
--	(section == "ecolog_guard_outfit") or
--	(section == "monolith_outfit") then
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_e", pos, lvid, gvid, actor)
--	
--	elseif (section == "svoboda_heavy_outfit") or
--	(section == "cs_heavy3b_outfit") or
--	(section == "specops_outfit") or
--	(section == "ecolog_guard_outfit") or
--	(section == "monolith_outfit") then
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_b", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_m", pos, lvid, gvid, actor)
--		alife():create("textile_patch_e", pos, lvid, gvid, actor)
		
	if (section == "compression_bag") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("rope", pos, lvid, gvid, actor) end
		
	elseif (section == "helm_cloth_mask") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		
	elseif (section == "itm_sleepbag") then
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 0.25) then alife():create("synthrope", pos, lvid, gvid, actor) end
		
	elseif (section == "itm_backpack") then
	    if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 0.25) then alife():create("synthrope", pos, lvid, gvid, actor) end
		
	elseif (section == "backpack_light") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("rope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("synthrope", pos, lvid, gvid, actor) end
		
	elseif (section == "backpack_heavy") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("rope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("rope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("synthrope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("synthrope", pos, lvid, gvid, actor) end
		
	elseif (section == "kit_hunt") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("rope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("rope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("synthrope", pos, lvid, gvid, actor) end
		if (math.random() < condition) then alife():create("synthrope", pos, lvid, gvid, actor) end
			
	elseif (section == "boots") then
		if (math.random() < 1.0) then alife():create("textile_patch_e", pos, lvid, gvid, actor) end
		if (math.random() < 0.1) then alife():create("synthrope", pos, lvid, gvid, actor) end
			
	elseif (section == "beadspread") then
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		
	elseif (section == "radio") or
	(section == "radio2") or
	(section == "walkie") or
	(section == "headlamp") or
	(section == "flashlight_broken") then
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.05) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("batteries_dead", pos, lvid, gvid, actor) end
		
	elseif (section == "underwear") then
		if (math.random() < 1.0) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		if (math.random() < 0.5) then alife():create("textile_patch_b", pos, lvid, gvid, actor) end
		
	elseif (section == "tarpaulin") then
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("textile_patch_m", pos, lvid, gvid, actor) end
		
	elseif (section == "ied_rpg") then
		if (math.random() < 1.0) then alife():create("ammo_og-7b", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("jar", pos, lvid, gvid, actor) end
		
	elseif (section == "ied") then
		if (math.random() < 1.0) then alife():create("explo_metalcan_powder", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("jar", pos, lvid, gvid, actor) end
		
	elseif (section == "detector_craft") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		
	elseif (section == "detector_simple") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		
	elseif (section == "detector_advanced") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("textolite", pos, lvid, gvid, actor) end
		
	elseif (section == "detector_elite") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("textolite", pos, lvid, gvid, actor) end
		
	elseif (section == "detector_scientific") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("copper_coil", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("textolite", pos, lvid, gvid, actor) end
		
	elseif (section == "geiger") then
		if (math.random() < 0.75) then alife():create("capacitors", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("batteries", pos, lvid, gvid, actor) end
		
	elseif (section == "itm_pda_common") or
	(section == "itm_pda_uncommon") or
	(section == "itm_pda_rare")  then
		if (math.random() < 1.0) then alife():create("transistors", pos, lvid, gvid, actor) end
		if (math.random() < 0.75) then alife():create("batteries", pos, lvid, gvid, actor) end
		
	elseif (section == "survival_kit") then
		if (math.random() < 1.0) then alife():create("medkit", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("bandage", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("antirad", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("drug_charcoal_5", pos, lvid, gvid, actor) end
		
	elseif (section == "medkit_army") then
		if (math.random() < 1.0) then alife():create("medkit", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("salicidic_acid", pos, lvid, gvid, actor) end
		
	elseif (section == "medkit_scientic") then
		if (math.random() < 1.0) then alife():create("medkit", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("antirad", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("tetanus", pos, lvid, gvid, actor) end
		if (math.random() < 1.0) then alife():create("drug_coagulant", pos, lvid, gvid, actor) end
		
	end
end
