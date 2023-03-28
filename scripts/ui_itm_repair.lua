-- ui_itm_repair
-- Alundaio
--[[
Copyright (C) 2012 Alundaio
This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License-]]
--]]
-------------------------------------------------------------------

local extra_repair = {
	["backpack_light"] = true,
	["backpack_heavy"] = true,
	["backpack_unloading"] = true,
	["kit_hunt"] = true,
}

local repair_dep = {
	{0,1}, -- �������
	{1,0}, -- �������
	{3,2}, -- �������
	{9,8}, -- �����
	{12,11,10,29}, -- �����
	{14,13}, -- ������
	{17,16,15}, -- �������
	{20,19,18}, -- �������
}

class "load_item" (CUIListBoxItem)
function load_item:__init(height) super(height)
	self.file_name		= "filename"

	self:SetTextColor(GetARGB(255, 170, 170, 170))

	self.fn = self:GetTextItem()
	self.fn:SetFont(GetFontLetterica18Russian())
	self.fn:SetEllipsis(true)
end


function load_item:__finalize()
end

-------------------------------------------------------------------
class "repair_ui" (CUIScriptWnd)

function repair_ui:__init(owner,obj,section) super()
	self.object = obj
	self.owner = owner
	self.section = section
	local ini = system_ini()
	self.use_condition = ini:r_bool_ex(section,"use_condition") or false
	self.min_condition = ini:r_float_ex(section,"repair_min_condition") or 0
	self.max_condition = ini:r_float_ex(section,"repair_max_condition") or 0
	self.add_condition = ini:r_float_ex(section,"repair_add_condition") or 0
	self.part_bonus = ini:r_float_ex(section,"repair_part_bonus") or 0
	self.use_parts = ini:r_bool_ex(section,"repair_use_parts") or false
	self.repair_type = ini:r_string_ex(section,"repair_type") or "all"
	self.repair_condition_type = ini:r_float_ex(section,"repair_condition_type") or 0

	self.repair_only = alun_utils.parse_list(ini,section,"repair_only",true)
	self.repair_refuse = alun_utils.parse_list(ini,section,"repair_refuse",true)

	self.parts_include = alun_utils.parse_list(ini,section,"repair_parts_include",true)
	self.parts_exclude = alun_utils.parse_list(ini,section,"repair_parts_exclude",true)

	self.use_actor_effects = ini:r_bool_ex(section,"repair_use_actor_effects",false)

	self:InitControls()
	self:InitCallBacks()
end

function repair_ui:__finalize()
end

function repair_ui:FillList()
	self.list_box:RemoveAll()

	local function fill_list(actor,obj)
		
		if not obj then return end
	
		local main_section = system_ini():r_string_ex(obj:section(),"repair_type") or obj:section()
		--printf("ORG: "..original_wpn)
		--if ((self.repair_only and self.repair_only[obj:section()]) or (self.repair_refuse == nil) or (self.repair_refuse[obj:section()] == nil))
		if (self.repair_only and self.repair_only[main_section]) then
			if (self.repair_type == "weapon" and IsWeapon(obj))
			or (self.repair_type == "outfit" and (IsOutfit(obj) or IsHeadgear(obj) or extra_repair[obj:section()]))
			or (self.repair_type == "all" and (IsWeapon(obj) or IsOutfit(obj) or IsHeadgear(obj) or extra_repair[obj:section()])) then
				local con = obj:condition()
				if (con and con >= self.min_condition) then
					self:AddItemToList(obj,self.list_box,con)
				end
			end
		end
	end

	db.actor:iterate_inventory(fill_list,db.actor)
end

function repair_ui:FillPartsList()
	self.list_box_parts:RemoveAll()

	if self.list_box:GetSize()==0 then return end

	local item = self.list_box:GetSelectedItem()
	if not (item) then
		return
	end

	local obj = level.object_by_id(item.item_id)
	local function fill_list(actor,itm)
		if (itm and itm:id() ~= item.item_id) then
			if (self.parts_include and self.parts_include[itm:section()]) 
			or (self.parts_exclude == nil and string.find(obj:section(),itm:section())) 
			--or (self.parts_exclude and self.parts_exclude[itm:section()] == nil and string.find(obj:section(),itm:section())) 
			then
				self:AddItemToList(itm,self.list_box_parts,system_ini():r_float_ex(itm:section(),"repair_part_bonus") or self.part_bonus)
			end
		end
	end

	db.actor:iterate_inventory(fill_list,db.actor)
end

function repair_ui:FillConditionList()
	self.list_box_condition:RemoveAll()

	if self.list_box:GetSize()==0 then return end
	
	local item = self.list_box:GetSelectedItem()
	if not (item) then return end
	
	local obj = level.object_by_id(item.item_id)
	if (not obj) then return end

	local text = game.translate_string("")
	for i = 0, 31 do
		if (IsWeapon(obj) 
		and (bit_and(obj:get_weapon_condition_type(),math.pow(2,i)) ~= 0) 
		and (bit_and(self.repair_condition_type,math.pow(2,i)) ~= 0)) 
		then
			local name = game.translate_string("st_condition_type_text_"..i+1)
			self:AddItemToConditionList(name,i,self.list_box_condition)
		end
	end
end

function repair_ui:InitControls()
	self:SetWndRect			(Frect():set(0,0,1024,768))
	self:SetWndPos			(vector2():set(240,120))

	self:SetAutoDelete(true)

	self.xml				= CScriptXmlInit()
	local ctrl
	self.xml:ParseFile			("ui_itm_main.xml")

	ctrl					= CUIWindow()
	self.xml:InitWindow			("itm_repair:file_item:main",0,ctrl)

	self.file_item_main_sz	= vector2():set(ctrl:GetWidth(),ctrl:GetHeight())

	self.xml:InitWindow			("itm_repair:file_item:fn",0,ctrl)
	self.file_item_fn_sz	= vector2():set(ctrl:GetWidth(),ctrl:GetHeight())

	self.xml:InitWindow			("itm_repair:file_item:fd",0,ctrl)
	self.file_item_fd_sz	= vector2():set(ctrl:GetWidth(),ctrl:GetHeight())

	self.form				= self.xml:InitStatic("itm_repair:form",self)
	
	--self.form:SetWndPos(vector2():set(device().width/2-(self.form:GetWidth()+70), device().height/2 - self.form:GetHeight()))
	self.form:SetWndPos(vector2():set(0, 0))

	-- Background for forms
	--self.xml:InitStatic("itm_repair:form:list_background",self.form)

	if (self.use_parts) then
		--self.xml:InitStatic("itm_repair:form:list_parts_background",self.form)
	end

	-- Item picture
	self.picture			= self.xml:InitStatic("itm_repair:form:icon",self.form)
	self.picture_parts		= self.xml:InitStatic("itm_repair:form:icon_parts",self.form)

	-- Repair tool picture
	self.pic = self.xml:InitStatic("itm_repair:form:icon_tool",self.form)

	local ini = system_ini()
	local inv_grid_width = ini:r_float_ex(self.section,"inv_grid_width") or 0 
	local inv_grid_height = ini:r_float_ex(self.section,"inv_grid_height") or 0
	local inv_grid_x = ini:r_float_ex(self.section,"inv_grid_x") or 0
	local inv_grid_y = ini:r_float_ex(self.section,"inv_grid_y") or 0

	local x1 = inv_grid_x*50
	local y1 = inv_grid_y*50

	local w = inv_grid_width*50
	local h = inv_grid_height*50

	local x2 = x1 + w
	local y2 = y1 + h

	local w,h = w,h
	if (utils.is_widescreen()) then
	w,h = w/1.5,h/1.2
	else
	w,h = w/1.3,h/1.3
	end
	self.pic:InitTexture("ui\\ui_icon_equipment")
	self.pic:SetTextureRect(Frect():set(x1,y1,x2,y2))
	self.pic:SetWndSize(vector2():set(w,h))

	if not (self.pic.x) then
		local pos = self.pic:GetWndPos()
		local posform = self.form:GetWndPos()
		self.pic.x = pos.x + posform.x
		self.pic.y = pos.y + posform.y
	end

	self.pic:SetWndPos(vector2():set(self.pic.x-w/2, self.pic.y-h/2))

	-- Caption
	self.caption_parts 		= self.xml:InitTextWnd("itm_repair:form:caption_parts",self.form)
	self.caption_repair		= self.xml:InitTextWnd("itm_repair:form:caption_repair",self.form)

	-- List Box
	--self.xml:InitFrame			("itm_repair:form:list_frame",self.form)

	self.list_box			= self.xml:InitListBox("itm_repair:form:list",self.form)

	
	self.list_box_condition = self.xml:InitListBox("itm_repair:form:list_condition",self.form)
	self:Register			(self.list_box_condition, "list_window_condition")
	
	
	self.list_box:ShowSelectedItem	(true)
	self:Register			(self.list_box, "list_window")

	if (self.use_parts) then
		-- Parts List Box
		self.list_pos = self.list_box:GetWndPos()

		self.list_box_parts			= self.xml:InitListBox("itm_repair:form:list_parts",self.form)
		--self.list_box_parts:SetWndPos(vector2():set(self.list_pos.x+self.list_box:GetWidth()+5, self.list_pos.y))

		--local frame = self.xml:InitFrame("itm_repair:form:list_frame_parts",self.form)
		--frame:SetWndPos(vector2():set(self.list_pos.x+self.list_box:GetWidth()+5, self.list_pos.y))

		self.list_box_parts:ShowSelectedItem(true)
		self:Register(self.list_box_parts, "list_window_parts")
	else
		--self.form:SetWndSize(vector2():set(self.list_box:GetWidth()+35, self.form:GetHeight()))
	end
	-- Button Repair
	ctrl					= self.xml:Init3tButton("itm_repair:form:btn_repair",	self.form)
	self:Register			(ctrl, "button_repair")

	-- Button Cancel
	ctrl = self.xml:Init3tButton	("itm_repair:form:btn_cancel",	self.form)
	self:Register			(ctrl, "button_back")
end

function repair_ui:InitCallBacks()
	self:AddCallback("button_repair",		ui_events.BUTTON_CLICKED,         self.OnButton_repair,			self)
	self:AddCallback("button_back",		ui_events.BUTTON_CLICKED,             self.OnButton_back_clicked,	self)

	self:AddCallback("list_window", ui_events.LIST_ITEM_CLICKED, 			  self.OnListItemClicked,		self)
	self:AddCallback("list_window_parts", ui_events.LIST_ITEM_CLICKED, 		  self.OnPartsListItemClicked,		self)
	self:AddCallback("list_window_condition", ui_events.LIST_ITEM_CLICKED, 		  self.OnConditionListItemClicked,		self)
end

function repair_ui:OnPartsListItemClicked()
	if self.list_box_parts:GetSize()==0 then return end

	local item = self.list_box_parts:GetSelectedItem()
	if not (item) then
		self.picture_parts:SetTextureRect(Frect():set(0,0,0,0))
		return
	end

	local se_item = item.item_id and alife_object(item.item_id)
	if (se_item == nil or not db.actor:object(se_item:section_name())) then
		self.list_box_parts:RemoveItem(item)
		return
	end

	local condition = (self.list_box_condition:GetSelectedItem())
	
	local sec = se_item:section_name()
	local part_bonus = system_ini():r_float_ex(sec,"repair_part_bonus") or self.part_bonus
	
	local con = self.add_condition
	if (condition) then con = con*0.3 end
	con = math.floor((con + part_bonus)*100)
	
	self.caption_repair:SetText("+"..con.."%")

	local w,h = item.width,item.height
	if (utils.is_widescreen()) then
	w,h = item.width/1.5,item.height/1.2
	else
	w,h = item.width/1.2,item.height/1.2
	end
	self.picture_parts:InitTexture("ui\\ui_icon_equipment")
	self.picture_parts:SetTextureRect(Frect():set(item.x1,item.y1,item.x2,item.y2))
	self.picture_parts:SetWndSize(vector2():set(w,h))

	if not (self.picture_parts.x) then
		local pos = self.picture_parts:GetWndPos()
		self.picture_parts.x = pos.x
		self.picture_parts.y = pos.y
	end

	self.picture_parts:SetWndPos(vector2():set(self.picture_parts.x-w/2, self.picture_parts.y-h/2))
end


function repair_ui:OnConditionListItemClicked()
	if self.list_box_condition:GetSize()==0 then return end

	local part_bonus = 0
	
	local item = self.list_box_parts:GetSelectedItem()
	local se_item = item and item.item_id and alife_object(item.item_id)
	if (se_item and db.actor:object(se_item:section_name())) then
		local sec = se_item:section_name()
		part_bonus = system_ini():r_float_ex(sec,"repair_part_bonus") or 0
	end
	
	local con = math.floor((self.add_condition*0.3+part_bonus)*100)
	self.caption_repair:SetText("+"..con.."%")
end



function repair_ui:OnListItemClicked()
	if self.list_box:GetSize()==0 then return end

	local item = self.list_box:GetSelectedItem()

	if not (item) then
		self.picture:SetTextureRect(Frect():set(0,0,0,0))
		return
	end

	local se_item = alife_object(item.item_id)
	if (se_item == nil or not db.actor:object(se_item:section_name())) then
		self.list_box:RemoveItem(item)
		return
	end

	local w,h = item.width,item.height
	if (utils.is_widescreen()) then
	w,h = item.width/1.5,item.height/1.2
	else
	w,h = item.width/1.2,item.height/1.2
	end
	self.picture:InitTexture("ui\\ui_icon_equipment")
	self.picture:SetTextureRect(Frect():set(item.x1,item.y1,item.x2,item.y2))
	self.picture:SetWndSize(vector2():set(w,h))

	if not (self.picture.x) then
		local pos = self.picture:GetWndPos()
		self.picture.x = pos.x
		self.picture.y = pos.y
	end

	self.picture:SetWndPos(vector2():set(self.picture.x-w/2, self.picture.y-h/2))


	local con = math.floor(self.add_condition*100)
	self.caption_repair:SetText("+"..con.."%")

	if (self.use_parts) then
		self.picture_parts:SetTextureRect(Frect():set(0,0,0,0))
		self.caption_parts:SetText("")
		self:FillPartsList()
	end
	
	if (self.repair_condition_type > 0) then
		self.caption_parts:SetText("")
		
		self:FillConditionList()
	end
	
end

function repair_ui:OnButton_back_clicked()
	if (self.use_condition and self.object) then 
		local r = self.object:get_remaining_uses()
		if (r+1 <= self.object:get_max_uses()) then
			self.object:set_remaining_uses(self.object:get_remaining_uses()+1)
		end
	else
		alife():create(self.section,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())
	end
	self:HideDialog()
end

function repair_ui:OnKeyboard(dik, keyboard_action)
	CUIScriptWnd.OnKeyboard(self,dik,keyboard_action)
	if (keyboard_action == ui_events.WINDOW_KEY_PRESSED) then
		if (dik == DIK_keys.DIK_RETURN) then

		elseif (dik == DIK_keys.DIK_ESCAPE) then
			self:OnButton_back_clicked()
		end
	end
	return true
end

function repair_ui:OnButton_repair()
	local index = self.list_box:GetSelectedIndex()
	if index == -1 then return end
	local item  = self.list_box:GetItemByIndex(index)

	local obj = item and level.object_by_id(item.item_id)
	if not (obj) then
		return
	end
	
	if (self.use_condition and self.object and self.object:get_remaining_uses() <= 0) then 
		local se_obj = alife_object(self.object:id())
		if (se_obj) then 
			alife():release(se_obj,true)
		end
	end
	
	local bonus = 0
	if (self.list_box_parts) then
	
				-- ponney68 repair item multi usage
		-- WEAPON REPAIR ITEMS
		-- sharpening_stones x4
		if self.section =="sharpening_stones_4" then
		alife():create("sharpening_stones_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sharpening_stones_3" then
		alife():create("sharpening_stones_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sharpening_stones_2" then
		alife():create("sharpening_stones", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end

		-- gun_oil x2
		if self.section =="gun_oil_2" then
		alife():create("gun_oil", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- gun_oil_ru_d x2
		if self.section =="gun_oil_ru_d_2" then
		alife():create("gun_oil_ru_d", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- gun_oil_ru x2
		if self.section =="gun_oil_ru_2" then
		alife():create("gun_oil_ru", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- solvent x2
		if self.section =="solvent_2" then
		alife():create("solvent", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- steel_wool x2
		if self.section =="steel_wool_2" then
		alife():create("steel_wool", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- grease x2
		if self.section =="grease_2" then
		alife():create("grease", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end

		-- cleaning_kit_p x3
		if self.section =="cleaning_kit_p_3" then
		alife():create("cleaning_kit_p_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="cleaning_kit_p_2" then
		alife():create("cleaning_kit_p", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- cleaning_kit_s x3
		if self.section =="cleaning_kit_s_3" then
		alife():create("cleaning_kit_s_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="cleaning_kit_s_2" then
		alife():create("cleaning_kit_s", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- cleaning_kit_r x3
		if self.section =="cleaning_kit_r_3" then
		alife():create("cleaning_kit_r_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="cleaning_kit_r_2" then
		alife():create("cleaning_kit_r", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- cleaning_kit_u x3
		if self.section =="cleaning_kit_u_3" then
		alife():create("cleaning_kit_u_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="cleaning_kit_u_2" then
		alife():create("cleaning_kit_u", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end

		-- toolkit_p
		if self.section =="toolkit_p" then
		alife():create("toolkit_p_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- toolkit_s
		if self.section =="toolkit_s" then
		alife():create("toolkit_s_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- toolkit_r
		if self.section =="toolkit_r" then
		alife():create("toolkit_r_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		
		-- repairkit_p
		if self.section =="repairkit_p" then
		alife():create("repairkit_p_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- repairkit_s
		if self.section =="repairkit_s" then
		alife():create("repairkit_s_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- repairkit_r
		if self.section =="repairkit_r" then
		alife():create("repairkit_r_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		

		-- ARMOR REPAIR ITEMS
		-- sewing_kit_b x4
		if self.section =="sewing_kit_b_4" then
		alife():create("sewing_kit_b_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sewing_kit_b_3" then
		alife():create("sewing_kit_b_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sewing_kit_b_2" then
		alife():create("sewing_kit_b", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- sewing_kit_a x4
		if self.section =="sewing_kit_a_4" then
		alife():create("sewing_kit_a_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sewing_kit_a_3" then
		alife():create("sewing_kit_a_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		if self.section =="sewing_kit_a_2" then
		alife():create("sewing_kit_a", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- glue_b x2
		if self.section =="glue_b_2" then
		alife():create("glue_b", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- glue_a x2
		if self.section =="glue_a_2" then
		alife():create("glue_a", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- glue_e x2
		if self.section =="glue_e_2" then
		alife():create("glue_e", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end

		-- armor_repair_fa x2
		if self.section =="armor_repair_fa_2" then
		alife():create("armor_repair_fa", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- helmet_repair
		if self.section =="helmet_repair_kit" then
		alife():create("helmet_repair_kit_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- armor_repair_pro x4
		if self.section =="armor_repair_pro" then
		alife():create("armor_repair_pro_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end
		-- toolkit_u
		if self.section =="toolkit_u" then
		alife():create("toolkit_u_0", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
		end	
	
		index = self.list_box_parts:GetSelectedIndex()
		if (index ~= -1) then
			item = self.list_box_parts:GetItemByIndex(index)
			local se_parts = item and item.item_id and alife_object(item.item_id)
			if (se_parts) then
				local sec = se_parts:section_name()
				bonus = system_ini():r_float_ex(sec,"repair_part_bonus") or self.part_bonus
				-- swiss knife
				if(db.actor)and(sec=="swiss")then
					alife():create("swiss", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- gun_oil x2
				if(se_parts)and(se_parts:section_name()=="gun_oil_2")then
				alife():create("gun_oil", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- gun_oil_ru_d x2
				if(se_parts)and(se_parts:section_name()=="gun_oil_ru_d_2")then
				alife():create("gun_oil_ru_d", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- gun_oil_ru x2
				if(se_parts)and(se_parts:section_name()=="gun_oil_ru_2")then
				alife():create("gun_oil_ru", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- solvent x2
				if(se_parts)and(se_parts:section_name()=="solvent_2")then
				alife():create("solvent", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- steel_wool x2
				if(se_parts)and(se_parts:section_name()=="steel_wool_2")then
				alife():create("steel_wool", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- grease x2
				if(se_parts)and(se_parts:section_name()=="grease_2")then
				alife():create("grease", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- cleaning_kit_p x3
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_p_3")then
				alife():create("cleaning_kit_p_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_p_2")then
				alife():create("cleaning_kit_p", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- cleaning_kit_s x3
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_s_3")then
				alife():create("cleaning_kit_s_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_s_2")then
				alife():create("cleaning_kit_s", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- cleaning_kit_r5 x3
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_r5_3")then
				alife():create("cleaning_kit_r5_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_r5_2")then
				alife():create("cleaning_kit_r5", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- cleaning_kit_r7 x3
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_r7_3")then
				alife():create("cleaning_kit_r7_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_r7_2")then
				alife():create("cleaning_kit_r7", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- cleaning_kit_u x3
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_u_3")then
				alife():create("cleaning_kit_u2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())						end
				if(se_parts)and(se_parts:section_name()=="cleaning_kit_u_2")then
				alife():create("cleaning_kit_u", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- toolkit_p x4
				if(se_parts)and(se_parts:section_name()=="toolkit_p_4")then
				alife():create("toolkit_p_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_p_3")then
				alife():create("toolkit_p_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_p_2")then
				alife():create("toolkit_p", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- toolkit_s x4
				if(se_parts)and(se_parts:section_name()=="toolkit_s_4")then
				alife():create("toolkit_s_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_s_3")then
				alife():create("toolkit_s_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_s_2")then
				alife():create("toolkit_s", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- toolkit_r5 x4
				if(se_parts)and(se_parts:section_name()=="toolkit_r5_4")then
				alife():create("toolkit_r5_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_r5_3")then
				alife():create("toolkit_r5_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_r5_2")then
				alife():create("toolkit_r5", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- toolkit_r7 x4
				if(se_parts)and(se_parts:section_name()=="toolkit_r7_4")then
				alife():create("toolkit_r7_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_r7_3")then
				alife():create("toolkit_r7_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_r7_2")then
				alife():create("toolkit_r7", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end

				-- ARMOR REPAIR ITEMS
				-- sewing_kit_b x4
				if(se_parts)and(se_parts:section_name()=="sewing_kit_b_4")then
				alife():create("sewing_kit_b_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_b_3")then
				alife():create("sewing_kit_b_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_b_2")then
				alife():create("sewing_kit_b", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- sewing_kit_a x4
				if(se_parts)and(se_parts:section_name()=="sewing_kit_a_4")then
				alife():create("sewing_kit_a_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_a_3")then
				alife():create("sewing_kit_a_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_a_2")then
				alife():create("sewing_kit_a", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end

				-- sewing_kit_h x4
				if(se_parts)and(se_parts:section_name()=="sewing_kit_h_4")then
				alife():create("sewing_kit_h_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_h_3")then
				alife():create("sewing_kit_h_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="sewing_kit_h_2")then
				alife():create("sewing_kit_h_1", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end

				-- glue_b x2
				if(se_parts)and(se_parts:section_name()=="glue_b_2")then
				alife():create("glue_b", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- glue_a x2
				if(se_parts)and(se_parts:section_name()=="glue_a_2")then
				alife():create("glue_a", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- glue_e x2
				if(se_parts)and(se_parts:section_name()=="glue_e_2")then
				alife():create("glue_e", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end

				-- armor_repair_fa x2
				if(se_parts)and(se_parts:section_name()=="armor_repair_fa_2")then
				alife():create("armor_repair_fa", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- helmet_repair x3
				if(se_parts)and(se_parts:section_name()=="helmet_repair_kit_3")then
				alife():create("helmet_repair_kit_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="helmet_repair_kit_2")then
				alife():create("helmet_repair_kit", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- armor_repair_pro x4
				if(se_parts)and(se_parts:section_name()=="armor_repair_pro_4")then
				alife():create("armor_repair_pro_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="armor_repair_pro_3")then
				alife():create("armor_repair_pro_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="armor_repair_pro_2")then
				alife():create("armor_repair_pro", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				-- toolkit_u x4
				if(se_parts)and(se_parts:section_name()=="toolkit_u_4")then
				alife():create("toolkit_u_3", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_u_3")then
				alife():create("toolkit_u_2", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				if(se_parts)and(se_parts:section_name()=="toolkit_u_2")then
				alife():create("toolkit_u", db.actor:position(), db.actor:level_vertex_id(), db.actor:game_vertex_id(), db.actor:id())
				end
				
				--[[
				if (se_se_parts:get_remaining_uses() > 1) then
					se_parts:set_remaining_uses(se_parts:get_remaining_uses()-1)
				else
					alife():release(se_parts,true)
				end
				
				--]]
				if (sec~="wpn_hand_hammer" and sec~="wpn_hand_crowbar") then
				    alife():release(se_parts,true)
				end
			end
		end
	end
	
	local k = 1
	index = self.list_box_condition:GetSelectedIndex()
	if (index ~= -1) then
		item = self.list_box_condition:GetItemByIndex(index)
		local change_cond = 0
		
		if (item) then
			local cond_type = obj:get_weapon_condition_type() or 0
			for j = 1, #repair_dep do
				local dep = repair_dep[j]
				
				printf("dep[1]="..dep[1].." item.code="..item.code)
				
				if (dep[1] == item.code) then
					for i = 2, #dep do
						cond_type = items_condition.remove_condition_type(cond_type,dep[i])
						obj:set_weapon_condition_type(cond_type)
					end
				end
			end
			
			cond_type = items_condition.remove_condition_type(cond_type,item.code)
			obj:set_weapon_condition_type(cond_type)
			k = 0.3
		end
	end

	local con = obj:condition()
	con = con + self.add_condition*k + bonus
	con = con <= 1 and con or 1
	obj:set_condition(con)

	self:HideDialog()

	if (self.use_actor_effects and actor_effects) then
		actor_effects.use_item(self.section.."_dummy")
	end
end

function repair_ui:AddItemToList(item,listbox,condition)
	local ini = system_ini()
	local _itm			= load_item(self.file_item_main_sz.y)
	local sec = item and item:section()
	local inv_name 		= item and game.translate_string(ini:r_string_ex(sec,"inv_name") or "none")

	_itm:SetWndSize		(self.file_item_main_sz)

	_itm.fn:SetWndPos(vector2():set(0,0))
	_itm.fn:SetWndSize	(self.file_item_fn_sz)
	_itm.fn:SetText		(inv_name)

	condition = math.ceil(condition*100)
	if (item) then
		_itm.fage     = _itm:AddTextField("+"..condition.."%", self.file_item_fd_sz.x)
		_itm.fage:SetFont	(GetFontLetterica16Russian())
		_itm.fage:SetWndPos	(vector2():set(self.file_item_fn_sz.x+4, 0))
		_itm.fage:SetWndSize(self.file_item_fd_sz)

		_itm.item_id = item:id()

		local inv_grid_width = ini:r_float_ex(sec,"inv_grid_width") or 0
		local inv_grid_height = ini:r_float_ex(sec,"inv_grid_height") or 0
		local inv_grid_x = ini:r_float_ex(sec,"inv_grid_x") or 0
		local inv_grid_y = ini:r_float_ex(sec,"inv_grid_y") or 0

		_itm.x1 = inv_grid_x*50
		_itm.y1 = inv_grid_y*50

		_itm.width = inv_grid_width*50
		_itm.height = inv_grid_height*50

		_itm.x2 = _itm.x1 + _itm.width
		_itm.y2 = _itm.y1 + _itm.height
	end

	--[[
	_itm.picture = self.xml:InitStatic("itm_repair:form:picture",self.form)
	_itm.picture:InitTexture("ui\\ui_icon_equipment")
	_itm.picture:SetTextureRect(Frect():set(_itm.x1,_itm.y1,_itm.x2,_itm.y2))
	_itm.picture:SetWndSize(vector2():set(inv_grid_width*50,inv_grid_height*50))
	--]]

	listbox:AddExistingItem(_itm)
end


function repair_ui:AddItemToConditionList(name,code,listbox)
	local _itm			= load_item(self.file_item_main_sz.y)

	_itm:SetWndSize		(self.file_item_main_sz)

	_itm.fn:SetWndPos(vector2():set(0,0))
	_itm.fn:SetWndSize	(self.file_item_fn_sz)
	_itm.fn:SetText		(name)
	_itm.code = code

	_itm.fage     = _itm:AddTextField(":"..code)
	_itm.fage:SetFont	(GetFontLetterica16Russian())
	_itm.fage:SetWndPos	(vector2():set(self.file_item_fn_sz.x+4, 0))
	_itm.fage:SetWndSize(self.file_item_fd_sz)

	listbox:AddExistingItem(_itm)
end
